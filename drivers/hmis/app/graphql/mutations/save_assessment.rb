###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class SaveAssessment < BaseMutation
    description 'Create/Save assessment as work-in-progress'

    argument :input, Types::HmisSchema::AssessmentInput, required: true

    field :assessment, Types::HmisSchema::Assessment, null: true

    def resolve(input:)
      assessment, errors = input.find_or_create_assessment
      return { errors: errors } if errors.any?

      # Update values
      assessment.form_processor.assign_attributes(
        values: input.values,
        hud_values: input.hud_values,
      )
      assessment.assign_attributes(
        user_id: hmis_user.user_id,
        assessment_date: assessment.form_processor.find_assessment_date_from_values || assessment.assessment_date,
      )

      # Validate the assessment date
      errors = Hmis::Hud::Validators::CustomAssessmentValidator.validate_assessment_date(assessment)
      errors.reject!(&:warning?)
      return { errors: errors } if errors.any?

      errors = HmisErrors::Errors.new
      is_valid = assessment.valid?
      is_valid = assessment.form_processor.valid? && is_valid
      if is_valid
        assessment.form_processor.save!
        assessment.touch
        assessment.save_in_progress
      else
        errors.add_ar_errors(assessment.errors&.errors)
        errors.add_ar_errors(assessment.form_processor&.errors&.errors)
        errors.deduplicate!
        assessment = nil
      end

      assessment&.reload
      {
        assessment: assessment,
        errors: errors,
      }
    end
  end
end
