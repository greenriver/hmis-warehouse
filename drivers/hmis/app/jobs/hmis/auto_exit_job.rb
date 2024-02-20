###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis
  class AutoExitJob < BaseJob
    include NotifierConfig

    def self.enabled?
      Hmis::AutoExitConfig.exists?
    end

    def perform
      return unless self.class.enabled?

      setup_notifier('HMIS Auto-Exit')
      auto_exit_projects = Set.new
      auto_exit_count = 0

      Hmis::Hud::Project.hmis.each do |project|
        config = Hmis::AutoExitConfig.config_for_project(project)
        next unless config.present?
        raise "Auto-exit config unusually low: #{config.length_of_absence_days}" if config.length_of_absence_days < 30

        project.enrollments.open_excluding_wip.each do |enrollment|
          most_recent_contact = if project.es_nbn? # Night-by-night Emergency Shelter
            # For NBN shelters, the most recent contact is the last bed night.
            # If the client had no bed nights, use the enrollment (entry date) as the last contact.
            enrollment.services.bed_nights.order(:date_provided).last || enrollment
          else
            [
              enrollment.services.order(:date_provided).last,
              enrollment.custom_services.order(:date_provided).last,
              enrollment.current_living_situations.order(:information_date).last,
              enrollment.custom_assessments.order(:assessment_date).last,
              enrollment,
            ].compact.max_by { |entity| contact_date_for_entity(entity) }
          end

          most_recent_contact_date = contact_date_for_entity(most_recent_contact)
          next unless (Date.current - most_recent_contact_date).to_i >= config.length_of_absence_days

          auto_exit_count += 1
          auto_exit_projects.add(project.id)
          auto_exit(enrollment, most_recent_contact)
        end
      end

      @notifier&.ping("Auto-exited #{auto_exit_count} Enrollments in #{auto_exit_projects.size} Projects")
    rescue StandardError => e
      puts e.message
      @notifier.ping('Failure in auto-exit job', { exception: e })
      Rails.logger.fatal e.message
    end

    private

    def auto_exit(enrollment, most_recent_contact)
      exit_date = contact_date_for_entity(most_recent_contact)
      # If most recent contact was a Bed Night service, the Exit Date should be the day after they received service
      exit_date += 1.day if most_recent_contact.is_a?(Hmis::Hud::Service) && most_recent_contact.record_type == 200
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
