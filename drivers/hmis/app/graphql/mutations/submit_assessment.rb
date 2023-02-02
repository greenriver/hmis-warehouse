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

      # Validate hudValues based on FormDefinition
      validation_errors = definition.validate_form_values(input.hud_values, nil)
      # If user has already confirmed any warnings, remove them
      validation_errors = validation_errors.filter { |e| e.severity != :warning } if input.confirmed
      errors.push(*validation_errors)

      return { assessment: nil, errors: errors } if errors.any?

      # Update values
      assessment.assessment_detail.assign_attributes(
        values: input.values,
        hud_values: definition.key_by_field_name(input.hud_values),
      )
      assessment.assign_attributes(
        user_id: hmis_user.user_id,
        date_updated: DateTime.current,
        assessment_date: assessment_date,
      )

      # Run processor to create/update related records
      assessment.assessment_detail.assessment_processor.run!

      # Run both validation checks so that we can return all errors
      assessment_valid = assessment.valid?
      assessment_detail_valid = assessment.assessment_detail.valid?

      if assessment_valid && assessment_detail_valid
        assessment.assessment_detail.save!
        assessment.save_not_in_progress
        # If this is an intake assessment, move the enrollment out of WIP status
        assessment.enrollment.save_not_in_progress if assessment.intake?
      else
        # TODO: remove all this and raise an exception if there were errors
        errors.push(*assessment.assessment_detail&.errors&.errors)
        errors.push(*assessment.errors&.errors)
        errors = errors.uniq { |e| "#{e.attribute}#{e.message}" }

        # Hide AssessmentDate error becuase it gets its own different message..
        errors = errors.reject { |e| e.attribute.to_s.downcase == 'assessmentdate' }
        # annoyingly the "type" is "must exist because of https://github.com/rails/rails/blob/83217025a171593547d1268651b446d3533e2019/activemodel/lib/active_model/error.rb#L65 so we cant really resolve the error type...
        assessment = nil
      end

      return {
        assessment: assessment,
        errors: errors,
      }
    end
  end
end
