###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: false

module Hmis
  class AutoExitJob < BaseJob
    # Automatically exits inactive HMIS enrollments based on project-specific Auto-Exit configuration.
    #
    # Behavior
    # - Runs against all HMIS projects by default; can be scoped by data_source or project_ids.
    # - Operates on households: if ANY member has a recent contact within the configured window,
    #   the entire household is skipped. Otherwise, ALL household members are exited together using
    #   a shared exit_date equal to the most recent contact across the household.
    # - Prevents auto-exit when any household member has an ACTIVE CE referral referencing that
    #   member's enrollment via source_enrollment_id OR target_enrollment_id.
    # - For ES Night-by-Night projects, the most recent contact is the latest bed night with a
    #   non-nil date_provided; if missing/invalid, falls back to the enrollment entry.
    # - For other project types, the most recent contact is the latest of:
    #   Service.date_provided (present), CustomService.date_provided, CurrentLivingSituation.information_date,
    #   CustomAssessment.assessment_date, or the Enrollment (entry).
    #
    # Exit Creation
    # - Creates Hmis::Hud::Exit with destination "No exit interview completed" and timestamps auto_exited.
    # - Creates a CustomAssessment at data collection stage 3 on the exit_date.
    # - Releases any assigned unit and closes any external referral via enrollment hooks.
    # - Skips enrollments that already have an exit record.
    include NotifierConfig

    def self.enabled?
      Hmis::ProjectAutoExitConfig.exists?
    end

    def perform(**args)
      return unless self.class.enabled?

      # don't track if there are arguments
      return _perform(**args) if args.present?

      instrument_as_maintenance_task do |run|
        _perform(**args)
        run.complete!
      end
    end

    def _perform(project_ids: nil, data_source_id: nil)
      setup_notifier('HMIS Auto-Exit')
      auto_exit_projects = Set.new
      auto_exit_count = 0

      project_scope = if project_ids.present?
        Hmis::Hud::Project.hmis.where(id: project_ids)
      elsif data_source_id
        Hmis::Hud::Project.hmis.where(data_source_id: data_source_id)
      else
        # By default, run against all HMIS data sources
        Hmis::Hud::Project.hmis
      end

      project_scope.each do |project|
        config = Hmis::ProjectAutoExitConfig.detect_best_config_for_project(project)
        next unless config.present?
        raise "Auto-exit config unusually low: #{config.length_of_absence_days}" if config.length_of_absence_days < 30

        project.households.active.not_in_progress.preload(:enrollments).each do |household|
          # Skip auto-exit if any household member has an active CE referral that references
          # one of the household enrollments as either the source or target enrollment.
          next if household_has_active_ce_referral?(household)

          # Get the most recent contact date for the whole household
          most_recent_contact = household.enrollments.
            map { |hhm| get_most_recent_contact(hhm, project) }.
            max_by { |entity| Hmis::Hud::Enrollment.contact_date_for_entity(entity) }

          most_recent_contact_date = Hmis::Hud::Enrollment.contact_date_for_entity(most_recent_contact)
          next unless most_recent_contact_date.present?
          # If any household member has a most recent contact that's within the length_of_absence_days, don't exit anyone in the household
          next unless (Date.current - most_recent_contact_date).to_i >= config.length_of_absence_days

          auto_exit_count += household.enrollments.size
          auto_exit_projects.add(project.id)
          Hmis::Hud::Base.transaction do
            # Auto-exit all household members together, setting the exit date equal to the most recent contact for any household member
            household.enrollments.each do |e|
              auto_exit(e, most_recent_contact, project: project) unless e.exit.present?
            end
          end
        end
      end

      @notifier&.ping("Auto-exited #{auto_exit_count} Enrollments in #{auto_exit_projects.size} Projects")
    end

    private

    def household_has_active_ce_referral?(household)
      return false unless Hmis::Ce.configuration.enabled?

      enrollment_ids = household.enrollments.map(&:id)
      return false if enrollment_ids.blank?

      rf_t = Hmis::Ce::Referral.arel_table
      cond = [
        rf_t[:source_enrollment_id].in(enrollment_ids),
        rf_t[:target_enrollment_id].in(enrollment_ids),
      ].reduce(:or)

      Hmis::Ce::Referral.active.where(cond).exists?
    end

    def get_most_recent_contact(enrollment, project)
      if project.es_nbn? # Night-by-night Emergency Shelter
        # For NBN shelters, the most recent contact is the last bed night.
        last_bed_night = enrollment.services.bed_nights.where.not(date_provided: nil).order(:date_provided).last
        # If the client had no bed nights, or the last bed night is before enrollment entry (invalid), use the enrollment (entry date) as the last contact.
        [last_bed_night, enrollment].compact.max_by { |entity| Hmis::Hud::Enrollment.contact_date_for_entity(entity) }
      else
        [
          enrollment.services.where.not(date_provided: nil).order(:date_provided).last,
          enrollment.custom_services.order(:date_provided).last,
          enrollment.current_living_situations.order(:information_date).last,
          enrollment.custom_assessments.order(:assessment_date).last,
          enrollment,
        ].compact.
          max_by { |entity| Hmis::Hud::Enrollment.contact_date_for_entity(entity) }
      end
    end

    def auto_exit(enrollment, most_recent_contact, project:)
      exit_date = Hmis::Hud::Enrollment.contact_date_for_entity(most_recent_contact)
      # If most recent contact was a Bed Night service, the Exit Date should be the day after they received service
      exit_date += 1.day if most_recent_contact.is_a?(Hmis::Hud::Service) && most_recent_contact.record_type == 200
      # If most recent contact was on Entry Date and this is a residential project, add 1 day to avoid Same-day-exit data quality errors
      exit_date += 1.day if exit_date == enrollment.entry_date && !project.allows_same_day_exit?

      user = Hmis::Hud::User.system_user(data_source_id: enrollment.data_source_id)

      exit_record = Hmis::Hud::Exit.new(
        personal_id: enrollment.personal_id,
        enrollment_id: enrollment.enrollment_id,
        data_source_id: enrollment.data_source_id,
        user_id: user.user_id,
        exit_date: exit_date,
        destination: ::Hud.util.destination_no_exit_interview_completed,
        auto_exited: DateTime.current,
      )

      assessment = Hmis::Hud::CustomAssessment.new(
        user_id: user.user_id,
        assessment_date: exit_date,
        data_collection_stage: 3,
        data_source_id: enrollment.data_source_id,
        personal_id: enrollment.personal_id,
        enrollment_id: enrollment.enrollment_id,
      )
      assessment.build_form_processor(exit: exit_record)

      raise ActiveRecord::RecordInvalid, exit_record if exit_record.invalid?

      assessment.save!

      # Release the unit that was assigned to this Enrollment (if applicable)
      enrollment.release_unit!(exit_date, user: system_user)
      # Close referral in External LINK system (if applicable)
      enrollment.close_referral!(current_user: system_user)
    end

    def system_user
      @system_user ||= Hmis::User.system_user
    end
  end
end
