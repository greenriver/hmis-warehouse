###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::AssessmentInput < Types::BaseInputObject
    argument :assessment_id, ID, 'Required if updating an existing assessment', required: false
    argument :enrollment_id, ID, 'Required if saving a new assessment', required: false
    argument :form_definition_id, ID, 'Required if saving a new assessment', required: false
    argument :values, Types::JsonObject, 'Raw form state as JSON', required: false
    argument :hud_values, Types::JsonObject, 'Transformed HUD values as JSON', required: false
    argument :confirmed, Boolean, 'Whether warnings have been confirmed', required: false

    def find_or_create_assessment
      errors = Mutations::CustomValidationErrors.new
      if assessment_id.present?
        # Updating an existing assessment
        assessment = Hmis::Hud::Assessment.editable_by(current_user).find_by(id: assessment_id)
        errors.add :assessment, :required unless assessment.present?
      elsif enrollment_id.present? && form_definition_id.present?
        # Creating a new assessment
        enrollment = Hmis::Hud::Enrollment.editable_by(current_user).find_by(id: enrollment_id)
        errors.add :enrollment, :required unless enrollment.present?

        form_definition = Hmis::Form::Definition.find_by(id: form_definition_id)
        errors.add :form_definition, :required unless form_definition.present?
      else
        errors.add :enrollment, :required
      end

      return [nil, errors.errors] if errors.any?

      # Create new Assessment (and AssessmentDetail) if one doesn't exist already
      assessment ||= Hmis::Hud::Assessment.new_with_defaults(
        enrollment: enrollment,
        user: Hmis::Hud::User.from_user(current_user),
        form_definition: form_definition,
      )

      [assessment, []]
    end

    # Get and validate the AssessmentDate based on form values and assessment type
    def get_and_validate_assessment_date(assessment, definition)
      assessment_date = nil
      errors = Mutations::CustomValidationErrors.new

      entry_date = assessment.enrollment.entry_date
      item = definition.assessment_date_item

      if assessment.intake?
        assessment_date = entry_date
      elsif item.present?
        assessment_date = hud_values[item.link_id]
        assessment_date = Date.parse(assessment_date) if assessment_date.present?
        errors.add item.field_name, :required unless assessment_date.present?
        errors.add item.field_name, :invalid, message: "must be after entry date (#{entry_date.strftime('%m/%d/%Y')})" if assessment_date && entry_date && assessment_date < entry_date
      elsif definition.hud_assessment?
        errors.add :assessmentDate, :required
      elsif !definition.hud_assessment?
        assessment_date = assessment.assessment_date || Date.today
      end

      Rails.logger.info(">>> assessment_date #{assessment_date}")
      [assessment_date, errors.errors]
    end
  end
end
