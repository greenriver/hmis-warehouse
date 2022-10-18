module Mutations
  class SaveAssessment < BaseMutation
    argument :assessment_id, ID, required: true
    argument :values, Types::JsonObject, required: true
    date_string_argument :assessment_date, 'Date with format yyyy-mm-dd', required: false

    field :assessment, Types::HmisSchema::Assessment, null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false

    def validate_input(assessment: nil)
      errors = []
      errors << InputValidationError.new('Assessment must exist', attribute: 'assessment_id') unless assessment.present?
      errors
    end

    def resolve(assessment_id:, values:, assessment_date: nil)
      user = hmis_user

      assessment = Hmis::Hud::Assessment.find_by(id: assessment_id)
      errors = validate_input(assessment: assessment)

      return { assessment: nil, errors: errors } if errors.present?

      assessment.update(
        user_id: user.user_id,
        date_updated: Date.today,
        assessment_date: assessment_date ? Date.strptime(assessment_date) : assessment.assessment_date,
      )
      assessment.assessment_detail.update(values: values)

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
