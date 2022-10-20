module Mutations
  class CreateAssessment < BaseMutation
    argument :enrollment_id, ID, required: true
    argument :form_definition_id, ID, required: true
    argument :values, Types::JsonObject, required: true
    argument :in_progress, Boolean, required: false
    date_string_argument :assessment_date, 'Date with format yyyy-mm-dd', required: false

    field :assessment, Types::HmisSchema::Assessment, null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false

    def validate_input(enrollment: nil, definition: nil)
      errors = []
      errors << InputValidationError.new('Enrollment must exist', attribute: 'enrollment_id') unless enrollment.present?
      errors << InputValidationError.new('Cannot get definition', attribute: 'form_definition_id') if enrollment.present? && definition.nil?
      errors
    end

    def resolve(enrollment_id:, form_definition_id:, values:, assessment_date: nil, in_progress: false)
      user = hmis_user

      enrollment = Hmis::Hud::Enrollment.find_by(id: enrollment_id)
      form_definition = Hmis::Form::Definition.find_by(id: form_definition_id)

      errors = validate_input(enrollment: enrollment, definition: form_definition)

      return { assessment: nil, errors: errors } if errors.present?

      assessment_attrs = {
        data_source_id: user.data_source_id,
        user_id: user.user_id,
        personal_id: enrollment.personal_id,
        enrollment_id: enrollment.enrollment_id,
        assessment_id: Hmis::Hud::Assessment.generate_assessment_id,
        assessment_date: assessment_date ? Date.strptime(assessment_date) : Date.today,
        assessment_location: enrollment.project.project_name,
        assessment_type: ::HUD.ignored_enum_value,
        assessment_level: ::HUD.ignored_enum_value,
        prioritization_status: ::HUD.ignored_enum_value,
        date_created: Date.today,
        date_updated: Date.today,
      }

      assessment = Hmis::Hud::Assessment.new(**assessment_attrs)
      assessment.assessment_detail = Hmis::Form::AssessmentDetail.new(
        definition: form_definition,
        data_collection_stage: 1,
        role: form_definition.role,
        status: 'draft',
        values: values,
      )

      if assessment.valid? && assessment.assessment_detail.valid?
        in_progress ? assessment.save_in_progress : assessment.save_not_in_progress
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
