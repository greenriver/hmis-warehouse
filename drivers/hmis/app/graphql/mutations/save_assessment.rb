module Mutations
  class SaveAssessment < BaseMutation
    description 'Create/Save assessment as work-in-progress'

    argument :input, Types::HmisSchema::AssessmentInput, required: true

    field :assessment, Types::HmisSchema::Assessment, null: true

    def resolve(input:)
      assessment, errors = input.find_or_create_assessment
      return { assessment: nil, errors: errors } if errors.any?

      definition = assessment.custom_form.definition
      enrollment = assessment.enrollment

      # Determine the Assessment Date and validate it
      assessment_date, errors = definition.find_and_validate_assessment_date(
        values: input.values,
        entry_date: enrollment.entry_date,
        exit_date: enrollment.exit_date,
      )
      return { assessment: nil, errors: errors } if errors.any?

      # Update values
      assessment.custom_form.assign_attributes(
        values: input.values,
        hud_values: input.hud_values,
      )
      assessment.assign_attributes(
        user_id: hmis_user.user_id,
        assessment_date: assessment_date,
      )

      if assessment.valid? && assessment.custom_form.valid?
        assessment.custom_form.save!
        assessment.save_in_progress
      else
        errors << assessment.errors
        errors << assessment.custom_form.errors
        assessment = nil
      end

      {
        assessment: assessment,
        errors: errors,
      }
    end
  end
end
