module Mutations
  class SubmitAssessment < BaseMutation
    description 'Create/Submit assessment, and create/update related HUD records'

    argument :input, Types::HmisSchema::AssessmentInput, required: true

    field :assessment, Types::HmisSchema::Assessment, null: true

    def resolve(input:)
      assessment, errors = input.find_or_create_assessment
      return { errors: errors } if errors.any?

      definition = assessment.custom_form.definition
      enrollment = assessment.enrollment

      errors = HmisErrors::Errors.new

      # HoH Exit constraints
      if enrollment.head_of_household? && assessment.exit?
        open_enrollments = Hmis::Hud::Enrollment.open_on_date.
          viewable_by(current_user).
          where(household_id: enrollment.household_id).
          where.not(id: enrollment.id)

        # Error: cannot exit HoH if there are any other open enrollments
        errors.add :assessment, :invalid, full_message: 'Cannot exit head of household because there are existing open enrollments. Please assign a new HoH.' if open_enrollments.any?
      end

      # Non-HoH Intake constraints
      if !enrollment.head_of_household? && assessment.intake?
        hoh_enrollment = Hmis::Hud::Enrollment.open_on_date.
          heads_of_households.
          viewable_by(current_user).
          where(household_id: enrollment.household_id).
          first

        # Error: HoH intake is WIP, so this assessment cannot be submitted yet
        errors.add :assessment, :invalid, full_message: 'Cannot submit intake assessment because the Head of Household\'s intake has not yet been completed.' if hoh_enrollment&.in_progress?
      end

      errors.add :assessment, :invalid, full_message: 'Cannot exit an incomplete enrollment. Please complete the entry assessment first.' if assessment.exit? && enrollment.in_progress?
      return { errors: errors } if errors.any?

      # Determine the Assessment Date and validate it
      assessment_date, date_validation_errors = definition.find_and_validate_assessment_date(
        values: input.values,
        entry_date: enrollment.entry_date,
        exit_date: enrollment.exit_date,
      )
      errors.push(*date_validation_errors)

      # Update values
      assessment.custom_form.assign_attributes(
        values: input.values,
        hud_values: input.hud_values,
      )
      assessment.assign_attributes(
        user_id: hmis_user.user_id,
        assessment_date: assessment_date || assessment.assessment_date,
      )

      # Validate form values based on FormDefinition
      validation_errors = assessment.custom_form.validate_form(ignore_warnings: input.confirmed)
      errors.push(*validation_errors)

      # Run processor to create/update related records
      assessment.custom_form.form_processor.run!

      # Run both validations
      is_valid = assessment.valid? && assessment.custom_form.valid?

      # Push errors from related records
      errors.add_ar_errors(assessment.custom_form&.form_processor&.assessment_related_record_errors)

      # If this is an existing assessment and all the errors are warnings, save changes before returning
      if errors.any? && assessment.id.present? && errors.all? { |e| e.is_a?(HmisErrors::Error) && e.warning? }
        assessment.custom_form.save!
        assessment.save!
        assessment.touch
      end

      return { errors: errors } if errors.any?

      if is_valid
        # We need to call save on the processor directly to get the before_save hook to invoke.
        # If this is removed, the Enrollment won't save.
        assessment.custom_form.form_processor.save!
        # Save CustomForm to save the rest of the related records
        assessment.custom_form.save!
        # Save the assessment as non-WIP
        assessment.save_not_in_progress
        # If this is an intake assessment, ensure the enrollment is no longer in WIP status
        enrollment.save_not_in_progress if assessment.intake?
        # Update DateUpdated on the Enrollment
        enrollment.touch
      else
        # These are potentially unfixable errors, so maybe we should throw a server error instead.
        # Leaving them visible to the user for now, as they are helpful in development.
        # *NOTE* These may fail to transform into the GQL ValidationError type
        errors.add_ar_errors(assessment.custom_form&.errors&.errors)
        errors.add_ar_errors(assessment.errors&.errors)
        assessment = nil
      end

      {
        assessment: assessment,
        errors: errors,
      }
    end
  end
end
