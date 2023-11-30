###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis
  class AutoExitJob < BaseJob
    def perform
      Hmis::Hud::Project.hmis.each do |project|
        config = Hmis::AutoExitConfig.config_for_project(project)
        next unless config.present?
        raise "Auto-exit config unusually low: #{config.length_of_absence_days}" if config.length_of_absence_days < 30

        project.enrollments.open_excluding_wip.each do |enrollment|
          most_recent_contact = if project.project_type == 1 # Night-by-night Emergency Shelter
            enrollment.services.bed_nights.order(:date_provided).last
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

          auto_exit(enrollment, most_recent_contact)
        end
      end
    end

    private

    def auto_exit(enrollment, most_recent_contact)
      exit_date = contact_date_for_entity(most_recent_contact)
      # If most recent contact was a Bed Night service, the Exit Date should be the day after they received service
      exit_date += 1.day if most_recent_contact.is_a?(Hmis::Hud::Service) && most_recent_contact.record_type == 200
      user = Hmis::Hud::User.system_user(data_source_id: enrollment.data_source_id)

      new_exit = Hmis::Hud::Exit.create!(
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
      assessment.build_form_processor(definition: nil)
      assessment.form_processor.assign_attributes(
        values: {},
        hud_values: {},
        exit_id: new_exit.id,
      )
      assessment.save!
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
      end
    end
  end
end
