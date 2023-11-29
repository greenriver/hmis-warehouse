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

        project.enrollments.open_excluding_wip.each do |enrollment|
          most_recent_contact = if project.project_type == 1 # Night-by-night Emergency Shelter
            enrollment.services.where(record_type: 200).order(:date_provided).last
          else
            [
              enrollment.services.order(:date_provided).last,
              enrollment.custom_services.order(:date_provided).last,
              enrollment.current_living_situations.order(:information_date).last,
              enrollment.custom_assessments.order(:assessment_date).last,
            ].compact.max_by { |entity| contact_date_for_entity(entity) }
          end

          next unless most_recent_contact.present?

          most_recent_contact_date = contact_date_for_entity(most_recent_contact)
          next unless (Date.today - most_recent_contact_date).to_i >= config.length_of_absence_days

          auto_exit(enrollment, most_recent_contact)
        end
      end
    end

    def configs
      @configs ||= Hmis::AutoExitConfig.all
    end

    private

    def auto_exit(enrollment, most_recent_contact)
      exit_date = contact_date_for_entity(most_recent_contact)
      # If most recent contact was a Bed Night service, the Exit Date should be the day after they received service
      exit_date += 1.day if most_recent_contact.is_a?(Hmis::Hud::Service) && most_recent_contact.record_type == 200
      Hmis::Hud::Exit.create!(
        personal_id: enrollment.personal_id,
        enrollment_id: enrollment.enrollment_id,
        data_source_id: enrollment.data_source_id,
        user_id: Hmis::Hud::User.system_user(data_source_id: enrollment.data_source_id).user_id,
        exit_date: exit_date,
        destination: 30,
        auto_exited: DateTime.now,
      )
      assessment = Hmis::Hud::CustomAssessment.new_with_defaults(
        enrollment: enrollment,
        user: Hmis::Hud::User.system_user(data_source_id: enrollment.data_source_id),
        form_definition: Hmis::Form::Definition.find_definition_for_role(:EXIT, project: enrollment.project),
      )
      assessment.data_collection_stage = 3
      assessment.assessment_date = exit_date
      assessment.form_processor.assign_attributes(
        values: {},
        hud_values: {},
      )
      assessment.form_processor.run!(owner: assessment, user: Hmis::User.system_user)
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
      end
    end
  end
end
