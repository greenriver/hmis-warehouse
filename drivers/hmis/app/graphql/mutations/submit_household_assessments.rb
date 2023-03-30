module Mutations
  class SubmitHouseholdAssessments < BaseMutation
    description 'Submit multiple assessments in a household'

    argument :assessment_ids, [ID], required: true
    argument :confirmed, Boolean, 'Whether warnings have been confirmed', required: false
    argument :validate_only, Boolean, 'Validate assessments but don\'t submit them', required: false

    field :assessments, [Types::HmisSchema::Assessment], null: true

    def resolve(assessment_ids:, confirmed:, validate_only: false)
      assessments = Hmis::Hud::CustomAssessment.viewable_by(current_user).
        where(id: assessment_ids).
        preload(:enrollment, :custom_form)

      enrollments = assessments.map(&:enrollment)

      errors = HmisErrors::Errors.new
      # Error: insufficient permissions
      errors.add :assessment, :not_allowed if enrollments.first.present? && !current_user.permissions_for?(enrollments.first, :can_edit_enrollments)
      return { errors: errors } if errors.any?

      # Error: not all assessments found
      errors.add :assessment, :not_found if assessments.count != assessment_ids.size

      # Error: assessments do not all belong to the same household
      household_ids = enrollments.map(&:household_id).uniq
      errors.add :assessment, :invalid, full_message: 'Assessments must all belong to the same household.' if household_ids.count != 1

      # Error: assessments do not have the same data collection stage
      data_collection_stages = assessments.pluck(:data_collection_stage).uniq
      errors.add :assessment, :invalid, full_message: 'Assessments must have the same data collection stage.' if data_collection_stages.count != 1
      return { errors: errors } if errors.any?

      # HoH Exit constraints
      includes_hoh = enrollments.map(&:relationship_to_ho_h).uniq.include?(1)
      if assessments.first.exit? && includes_hoh
        # "Date.tomorrow" because it's OK if the exit date is today, but not if there is no exit date, or if the exit date is in the future (shouldn't happen)
        open_enrollments = Hmis::Hud::Enrollment.viewable_by(current_user).open_on_date(Date.tomorrow).
          where(household_id: household_ids.first).
          where.not(enrollment_id: enrollments.map(&:enrollment_id))

        # Error: cannot exit HoH if there are any other open enrollments
        errors.add :assessment, :invalid, full_message: 'Cannot exit head of household because there are existing open enrollments. Please assign a new HoH, or exit all open enrollments.' if open_enrollments.any?

        # Error: WIP enrollments cannot be exited
        errors.add :assessment, :invalid, full_message: 'Cannot exit incomplete enrollments. Please complete entry assessments first.' if enrollments.any?(&:in_progress?)
      end

      # Non-HoH Intake constraints
      if assessments.first.intake? && !includes_hoh
        hoh_enrollment = Hmis::Hud::Enrollment.viewable_by(current_user).
          heads_of_households.
          where(household_id: household_ids.first).
          first

        # Error: HoH intake is WIP, so member assessments cannot be submitted yet
        errors.add :assessment, :invalid, full_message: 'Please include the head of household. Other household members cannot be entered without the HoH.' if hoh_enrollment&.in_progress?
      end

      return { errors: errors } if errors.any?

      # Validate form values based on FormDefinition
      assessments.each do |assessment|
        # FIXME: this needs to validate against the PROPOSED dates, not the actual dates
        # Validate the assessment date
        assessment_date, date_validation_errors = assessment.custom_form.definition.find_and_validate_assessment_date(
          values: assessment.custom_form.values,
          enrollment: assessment.enrollment,
          ignore_warnings: confirmed,
        )
        errors.add_with_record_id(date_validation_errors, assessment.id)

        # Set the assessment date (doesn't happen on WIP save)
        assessment.assign_attributes(
          assessment_date: assessment_date || assessment.assessment_date,
          user_id: hmis_user.user_id,
        )

        # Collect other form validations
        form_validations = assessment.custom_form.collect_form_validations(ignore_warnings: confirmed)
        errors.add_with_record_id(form_validations, assessment.id)
      end

      all_valid = true
      # Run form processor on each assessment, validate all records
      assessments.each do |assessment|
        # Run processor to create/update related records
        assessment.custom_form.form_processor.run!
        # Run both validations
        is_valid = assessment.valid? && assessment.custom_form.valid?
        all_valid = false unless is_valid

        # Collect validations and warnings from AR Validator classes
        record_validations = assessment.custom_form.collect_record_validations(
          user: current_user,
          ignore_warnings: confirmed,
        )
        errors.add_with_record_id(record_validations, assessment.id)
      end

      # Return any validation errors
      return { errors: errors } if errors.any?

      return { assessments: assessments, errors: [] } if validate_only

      if all_valid
        # Save all assessments
        assessments.each do |assessment|
          # We need to call save on the processor directly to get the before_save hook to invoke.
          # If this is removed, the Enrollment won't save.
          assessment.custom_form.form_processor.save!
          # Save CustomForm to save the rest of the related records
          assessment.custom_form.save!
          # Save the assessment as non-WIP
          assessment.save_not_in_progress
          # If this is an intake assessment, ensure the enrollment is no longer in WIP status
          assessment.enrollment.save_not_in_progress if assessment.intake?
          # Update DateUpdated on the Enrollment
          assessment.enrollment.touch
        end
      else
        # These are potentially unfixable errors. Maybe should be server error instead.
        # For now, return them all because they are useful in development.
        assessments.each do |assessment|
          errors.add_ar_errors(assessment.custom_form&.errors&.errors)
          errors.add_ar_errors(assessment.errors&.errors)
        end
        assessments = []
      end

      {
        assessments: assessments,
        errors: errors,
      }
    end
  end
end
