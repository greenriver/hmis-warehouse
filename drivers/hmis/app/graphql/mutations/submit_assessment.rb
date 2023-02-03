module Mutations
  class SubmitAssessment < BaseMutation
    description 'Create/Submit assessment, and create/update related HUD records'

    argument :input, Types::HmisSchema::AssessmentInput, required: true

    field :assessment, Types::HmisSchema::Assessment, null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false

    def resolve(input:)
      assessment, errors = input.find_or_create_assessment
      return { assessment: nil, errors: errors } if errors.any?

      definition = assessment.assessment_detail.definition
      enrollment = assessment.enrollment

      # Determine the Assessment Date (same as Information Date) and validate it
      assessment_date, errors = definition.find_and_validate_assessment_date(
        hud_values: input.hud_values,
        entry_date: enrollment.entry_date,
        exit_date: enrollment.exit_date,
      )

      # Validate form values based on FormDefinition
      validation_errors = definition.validate_form_values(input.hud_values, nil)
      # If user has already confirmed any warnings, remove them
      validation_errors = validation_errors.reject(&:warning?) if input.confirmed
      errors.push(*validation_errors)

      # Update values
      assessment.assessment_detail.assign_attributes(
        values: input.values,
        hud_values: definition.key_by_field_name(input.hud_values),
      )
      assessment.assign_attributes(
        user_id: hmis_user.user_id,
        date_updated: DateTime.current,
        assessment_date: assessment_date || assessment.assessment_date,
      )

      # If this is an existing assessment and all the errors are warnings, save changes before returning.
      # (NOTE: We could/should do this for new assessments, too, but it's a bit more complicated
      # because we'd need to send back the newly created assessment ID to the frontend.)
      if errors.all?(&:warning?) && assessment.id.present?
        assessment.assessment_detail.save!
        assessment.save!
      end

      return { assessment: nil, errors: errors } if errors.any?

      # Run processor to create/update related records
      assessment.assessment_detail.assessment_processor.run!

      # Run both validations
      assessment_valid = assessment.valid?
      assessment_detail_valid = assessment.assessment_detail.valid?

      if assessment_valid && assessment_detail_valid
        assessment.assessment_detail.save!
        assessment.save_not_in_progress
        # If this is an intake assessment, move the enrollment out of WIP status
        assessment.enrollment.save_not_in_progress if assessment.intake?
      else
        # These are potentially unfixable errors, so maybe we should throw a server error instead.
        # Leaving them visible to the user for now, while we QA the feature.
        errors.push(*assessment.assessment_detail&.errors&.errors)
        errors.push(*assessment.errors&.errors)
        assessment = nil
      end

      return {
        assessment: assessment,
        errors: errors,
      }
    end
  end
end
