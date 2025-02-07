###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis
  class AutoExitJob < BaseJob
    include NotifierConfig

    def self.enabled?
      Hmis::ProjectAutoExitConfig.exists?
    end

    # todo add project id param
    def perform
      return unless self.class.enabled?

      setup_notifier('HMIS Auto-Exit')
      auto_exit_projects = Set.new
      auto_exit_count = 0

      Hmis::Hud::Project.hmis.each do |project|
        config = Hmis::ProjectAutoExitConfig.detect_best_config_for_project(project)
        next unless config.present?
        raise "Auto-exit config unusually low: #{config.length_of_absence_days}" if config.length_of_absence_days < 30

        project.households.active.not_in_progress.preload(:enrollments).each do |household|
          # Get the most recent contact date for the whole household
          most_recent_contact = household.enrollments.
            map { |hhm| get_most_recent_contact(hhm, project) }.
            max_by { |entity| contact_date_for_entity(entity) }

          most_recent_contact_date = contact_date_for_entity(most_recent_contact)
          next unless most_recent_contact_date.present?
          # If any household member has a most recent contact that's within the length_of_absence_days, don't exit anyone in the household
          next unless (Date.current - most_recent_contact_date).to_i >= config.length_of_absence_days

          auto_exit_count += household.enrollments.size
          auto_exit_projects.add(project.id)
          Hmis::Hud::Base.transaction do
            # Auto-exit all household members together, setting the exit date equal to the most recent contact for any household member
            household.enrollments.each do |e|
              auto_exit(e, most_recent_contact, project_type: project.project_type)
            end
          end
        end
      end

      @notifier&.ping("Auto-exited #{auto_exit_count} Enrollments in #{auto_exit_projects.size} Projects")
    end

    private

    def get_most_recent_contact(enrollment, project)
      if project.es_nbn? # Night-by-night Emergency Shelter
        # For NBN shelters, the most recent contact is the last bed night.
        last_bed_night = enrollment.services.bed_nights.where.not(date_provided: nil).order(:date_provided).last
        # If the client had no bed nights, or the last bed night is before enrollment entry (invalid), use the enrollment (entry date) as the last contact.
        [last_bed_night, enrollment].compact.max_by { |entity| contact_date_for_entity(entity) }
      else
        [
          enrollment.services.where.not(date_provided: nil).order(:date_provided).last,
          enrollment.custom_services.order(:date_provided).last,
          enrollment.current_living_situations.order(:information_date).last,
          enrollment.custom_assessments.order(:assessment_date).last,
          enrollment,
        ].compact.max_by { |entity| contact_date_for_entity(entity) }
      end
    end

    def auto_exit(enrollment, most_recent_contact, project_type:)
      exit_date = contact_date_for_entity(most_recent_contact)
      # If most recent contact was a Bed Night service, the Exit Date should be the day after they received service
      exit_date += 1.day if most_recent_contact.is_a?(Hmis::Hud::Service) && most_recent_contact.record_type == 200
      # If most recent contact was on Entry Date and this is a residential project, add 1 day to avoid Same-day-exit data quality errors
      exit_date += 1.day if exit_date == enrollment.entry_date && HudUtility2024.residential_project_type_ids.include?(project_type)

      user = Hmis::Hud::User.system_user(data_source_id: enrollment.data_source_id)

      exit_record = Hmis::Hud::Exit.new(
        personal_id: enrollment.personal_id,
        enrollment_id: enrollment.enrollment_id,
        data_source_id: enrollment.data_source_id,
        user_id: user.user_id,
        exit_date: exit_date,
        destination: HudUtility2024.destination_no_exit_interview_completed,
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

    def contact_date_for_entity(entity)
      case entity
      when Hmis::Hud::Service, Hmis::Hud::CustomService
        entity.date_provided
      when Hmis::Hud::CurrentLivingSituation
        entity.information_date
      when Hmis::Hud::CustomAssessment
        entity.assessment_date
      when Hmis::Hud::Enrollment
        entity.entry_date
      else
        raise "Unknown entity '#{entity.class}'"
      end
    end

    def system_user
      @system_user ||= Hmis::User.system_user
    end
  end
end
