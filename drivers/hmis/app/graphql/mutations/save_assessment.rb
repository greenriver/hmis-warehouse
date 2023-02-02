module Mutations
  class SaveAssessment < BaseMutation
    description 'Create/Save assessment as work-in-progress'

    argument :input, Types::HmisSchema::AssessmentInput, required: true

    field :assessment, Types::HmisSchema::Assessment, null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false

    def resolve(input:)
      assessment, errors = input.find_or_create_assessment
      return { assessment: nil, errors: errors } if errors.any?

      definition = assessment.assessment_detail.definition

      # Determine the Assessment Date (same as Information Date) and validate it
      assessment_date, errors = input.get_and_validate_assessment_date(assessment, definition)
      return { assessment: nil, errors: errors } if errors.any?

      # Update values
      assessment.assessment_detail.assign_attributes(values: input.values)
      assessment.assign_attributes(
        user_id: hmis_user.user_id,
        date_updated: DateTime.current,
        assessment_date: assessment_date,
      )

      if assessment.valid? && assessment.assessment_detail.valid?
        assessment.assessment_detail.save!
        assessment.save_in_progress
      else
        errors << assessment.errors
        errors << assessment.assessment_detail.errors
        assessment = nil
      end

      {
        assessment: assessment,
        errors: errors,
      }
    end
  end
end
