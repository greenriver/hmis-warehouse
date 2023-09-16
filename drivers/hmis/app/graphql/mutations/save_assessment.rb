###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class SaveAssessment < BaseMutation
    description 'Create/Save assessment as work-in-progress'

    argument :input, Types::HmisSchema::AssessmentInput, required: true
    argument :assessment_lock_version, Integer, required: false

    field :assessment, Types::HmisSchema::Assessment, null: true

    def resolve(input:, assessment_lock_version: nil)
      assessment, errors = input.find_or_create_assessment
      return { errors: errors } if errors.any?

      # Update values
      assessment.lock_version = assessment_lock_version if assessment_lock_version
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

      if assessment.valid?(:form_submission)
        assessment.save_submitted_assessment!(current_user: current_user, as_wip: true)
      else
        errors = HmisErrors::Errors.new
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
