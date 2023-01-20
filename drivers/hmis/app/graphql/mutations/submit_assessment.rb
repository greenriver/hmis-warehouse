module Mutations
  class SubmitAssessment < BaseMutation
    description 'Create/Submit assessment, and create/update related HUD records'

    argument :assessment_id, ID, 'Required if updating an existing assessment', required: false
    argument :enrollment_id, ID, 'Required if saving a new assessment', required: false
    argument :form_definition_id, ID, 'Required if saving a new assessment', required: false
    argument :values, Types::JsonObject, 'Form state as JSON', required: true
    argument :hud_values, Types::JsonObject, 'Transformed HUD values as JSON', required: false
    date_string_argument :assessment_date, 'Date with format yyyy-mm-dd', required: false

    field :assessment, Types::HmisSchema::Assessment, null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false

    def resolve(assessment_id: nil, enrollment_id: nil, form_definition_id: nil, values:, hud_values: nil, assessment_date: nil)
      errors = []

      # Look up Assessment or Enrollment
      if assessment_id
        assessment = Hmis::Hud::Assessment.viewable_by(current_user).find_by(id: assessment_id)
        errors << InputValidationError.new('Assessment must exist', attribute: 'assessment_id') unless assessment.present?
      elsif enrollment_id
        enrollment = Hmis::Hud::Enrollment.viewable_by(current_user).find_by(id: enrollment_id)
        errors << InputValidationError.new('Enrollment must exist', attribute: 'enrollment_id') unless enrollment.present?

        form_definition = Hmis::Form::Definition.find_by(id: form_definition_id)
        errors << InputValidationError.new('Form definition must exist') unless form_definition.present?
      else
        errors << InputValidationError.new('Enrollment ID or Assessment ID must exist', attribute: 'enrollment_id')
      end

      return { assessment: nil, errors: errors } if errors.present?

      # Create new Assessment (and AssessmentDetail) if one doesn't exist already
      assessment ||= Hmis::Hud::Assessment.new_with_defaults(
        enrollment: enrollment,
        user: hmis_user,
        form_definition: form_definition,
        assessment_date: assessment_date ? Date.strptime(assessment_date) : Date.today,
      )

      # Update values
      assessment.assessment_detail.assign_attributes(values: values, hud_values: hud_values)
      assessment.assign_attributes(
        user_id: hmis_user.user_id,
        date_updated: DateTime.current,
        assessment_date: assessment_date ? Date.strptime(assessment_date) : assessment.assessment_date,
      )

      # TODO: return validation errors for processed records

      if assessment.valid? && assessment.assessment_detail.valid?
        assessment.assessment_detail.save!
        assessment.assessment_detail.assessment_processor.run!
        assessment.save_not_in_progress
        # If this is an intake assessment, move the enrollment out of WIP status
        assessment.enrollment.save_not_in_progress if assessment.intake?
      else
        errors << assessment.errors
        errors << assessment.assessment_detail.errors
        assessment = nil
      end

      return {
        assessment: assessment,
        errors: errors,
      }
    end
  end
end
