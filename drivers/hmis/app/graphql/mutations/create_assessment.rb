module Mutations
  class CreateAssessment < BaseMutation
    argument :enrollment_id, ID, required: true
    argument :assessment_role, String, required: true
    date_string_argument :assessment_date, 'Date with format yyyy-mm-dd', required: false

    field :assessment, Types::HmisSchema::Assessment, null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false

    def validate_input(enrollment: nil, definition: nil)
      errors = []
      errors << InputValidationError.new('Enrollment must exist', attribute: 'enrollment_id') unless enrollment.present?
      errors << InputValidationError.new('Cannot get definition for assessment role', attribute: 'assessment_role') if enrollment.present? && definition.nil?
      errors
    end

    def resolve(enrollment_id:, assessment_role:, assessment_date: nil)
      user = hmis_user

      enrollment = Hmis::Hud::Enrollment.find_by(id: enrollment_id)
      form_definition = enrollment&.project&.present? ? Hmis::Form::Definition.find_definition_for_project(enrollment.project, role: assessment_role) : nil

      errors = validate_input(enrollment: enrollment, definition: form_definition)

      return { assessment: nil, errors: errors } if errors.present?

      assessment_attrs = {
        data_source_id: user.data_source_id,
        user_id: user.user_id,
        personal_id: enrollment.personal_id,
        assessment_id: Hmis::Hud::Assessment.generate_assessment_id,
        assessment_date: assessment_date ? Date.strptime(assessment_date) : Date.today,
        assessment_location: enrollment.project.project_name,
        assessment_type: ::HUD.ignored_enum_value,
        assessment_level: ::HUD.ignored_enum_value,
        prioritization_status: ::HUD.ignored_enum_value,
        date_created: Date.today,
        date_updated: Date.today,
      }

      assessment = enrollment.assessments.new(**assessment_attrs)
      assessment.assessment_detail = Hmis::Form::AssessmentDetail.new(
        definition: form_definition,
        data_collection_stage: 1,
        role: assessment_role,
        status: 'draft',
      )

      if assessment.valid? && assessment.assessment_detail.valid?
        assessment.save!
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
