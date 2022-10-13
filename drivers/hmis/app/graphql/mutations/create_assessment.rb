module Mutations
  class CreateAssessment < BaseMutation
    argument :enrollment_id, ID, required: false
    argument :assessment_role, String, required: true

    field :assessment, Types::HmisSchema::Assessment, null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false

    def resolve(enrollment_id:, assessment_role:)
      user = hmis_user

      enrollment = Hmis::Hud::Enrollment.find_by(id: enrollment_id)
      form_definition = Hmis::Form::Definition.find_definition_for_project(enrollment.project, role: assessment_role)

      errors = []

      errors << 'Form Definition not found' unless form_definition.present?

      assessment_attrs = {
        data_source_id: user.data_source_id,
        user_id: user.user_id,
        personal_id: enrollment.personal_id,
        assessment_id: Hmis::Hud::Assessment.generate_assessment_id,
        assessment_date: Date.parse('2019-01-01'),
        assessment_location: 'Test Location',
        assessment_type: 1,
        assessment_level: 1,
        prioritization_status: 1,
        date_created: Date.parse('2019-01-01'),
        date_updated: Date.parse('2019-01-01'),
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
        errors: [],
      }
    end
  end
end
