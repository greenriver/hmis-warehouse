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
      errors = HmisErrors::CustomValidationErrors.new

      if assessment_id.present?
        # Updating an existing assessment
        assessment = Hmis::Hud::Assessment.editable_by(current_user).find_by(id: assessment_id)
        errors.add :assessment, :required unless assessment.present?
      elsif enrollment_id.present? && form_definition_id.present?
        # Creating a new assessment
        enrollment = Hmis::Hud::Enrollment.editable_by(current_user).find_by(id: enrollment_id)
        form_definition = Hmis::Form::Definition.find_by(id: form_definition_id)
        errors.add :enrollment, :required unless enrollment.present?
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
  end
end
