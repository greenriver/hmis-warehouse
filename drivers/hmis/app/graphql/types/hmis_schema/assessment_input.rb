###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::AssessmentInput < Types::BaseInputObject
    argument :form_definition_id, ID, 'Form Definition that was used to perform this assessment', required: true
    argument :assessment_id, ID, 'Required if updating an existing assessment', required: false
    argument :enrollment_id, ID, 'Required if saving a new assessment', required: false
    argument :values, Types::JsonObject, 'Raw form state as JSON', required: true
    argument :hud_values, Types::JsonObject, 'Transformed HUD values as JSON', required: true
    argument :confirmed, Boolean, 'Whether warnings have been confirmed', required: false
    argument :validate_only, Boolean, 'Validate assessment but don\'t submit it', required: false

    def find_or_create_assessment
      form_definition = Hmis::Form::Definition.find_by(id: form_definition_id)
      raise HmisErrors::ApiError, 'FormDefinition not found' unless form_definition.present?

      # If updating existing assessment, find it
      if assessment_id.present?
        assessment = Hmis::Hud::CustomAssessment.viewable_by(current_user).find_by(id: assessment_id)
        raise HmisErrors::ApiError, 'Assessment not found' unless assessment.present?
        raise HmisErrors::ApiError, 'No form processor on assessment' unless assessment.form_processor.present?

        enrollment = assessment.enrollment
      # If creating a new assessment, find enrollment
      elsif enrollment_id.present?
        enrollment = Hmis::Hud::Enrollment.viewable_by(current_user).find_by(id: enrollment_id)
        raise HmisErrors::ApiError, 'Enrollment not found' unless enrollment.present?
      else
        raise HmisErrors::ApiError, 'Assessment or Enrollment must be specified'
      end

      raise HmisErrors::ApiError, 'Access Denied' unless current_user.permissions_for?(enrollment, :can_edit_enrollments)

      # Validation: can't create 2nd intake/exit assessment
      unless assessment.present?
        errors = HmisErrors::Errors.new
        errors.add :assessment, :invalid, full_message: 'An intake assessment for this enrollment already exists.' if form_definition.intake? && enrollment.intake_assessment.present?
        errors.add :assessment, :invalid, full_message: 'An exit assessment for this enrollment already exists.' if form_definition.exit? && enrollment.exit_assessment.present?
        return [nil, errors.errors] if errors.any?
      end

      if assessment.present?
        # Update the Form Definition on the processor. It's possible that it's different from the last
        # definition that was used to submit this assessment.
        assessment.form_processor.definition = form_definition
        # Need to set this directly so AR can resolve the has_one-through for the newly built record
        assessment.definition = form_definition
      else
        # Create new Assessment (and FormProcessor) if one doesn't exist already
        assessment = Hmis::Hud::CustomAssessment.new_with_defaults(
          enrollment: enrollment,
          user: Hmis::Hud::User.from_user(current_user),
          form_definition: form_definition,
        )
      end

      [assessment, []]
    end
  end
end
