module Mutations
  class SubmitHouseholdAssessments < BaseMutation
    description 'Submit multiple assessments in a household'

    argument :assessment_ids, [ID], required: true
    argument :confirmed, Boolean, 'Whether warnings have been confirmed', required: false

    field :assessments, [Types::HmisSchema::Assessment], null: true

    def resolve(assessment_ids:, confirmed:)
      errors = HmisErrors::Errors.new

      assessments = Hmis::Hud::Assessment.editable_by(current_user).
        where(id: assessment_ids).
        preload(:enrollment, :assessment_detail)

      enrollments = assessments.map(&:enrollment)

      # Error: not all assessments found
      errors.add :assessment, :not_found if assessments.count != assessment_ids.size

      # Error: assessments do not all belong to the same household
      household_ids = enrollments.map(&:household_id).uniq
      errors.add :assessment, :invalid, full_message: 'Assessments must all belong to the same household.' if household_ids.count != 1

      # Error: assessments do not have the same data collection stage
      data_collection_stages = assessments.map { |a| a.assessment_detail.data_collection_stage }.uniq
      errors.add :assessment, :invalid, full_message: 'Assessments must have the same data collection stage.' if data_collection_stages.count != 1
      return { errors: errors } if errors.any?

      # HoH Exit constraints
      includes_hoh = enrollments.map(&:relationship_to_ho_h).uniq.include?(1)
      if assessments.first.exit? && includes_hoh
        # FIXME: If exit dates can be in the future, `open_on_date` should check against HoH exit date
        # and the max assessment date on all assessments being submitted. Maybe do in Exit validator instead.
        open_enrollments = Hmis::Hud::Enrollment.viewable_by(current_user).open_on_date.
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
        validation_errors = assessment.assessment_detail.validate_form(ignore_warnings: confirmed)
        errors.add_with_record_id(validation_errors, assessment.id)
      end

      return { errors: errors } if errors.any?

      # Run form processor on each assessment, validate all records
      assessments.each do |assessment|
        assessment.assign_attributes(user_id: hmis_user.user_id)
        # Run processor to create/update related records
        assessment.assessment_detail.assessment_processor.run!
        # Run both validations
        assessment_valid = assessment.valid?
        assessment_detail_valid = assessment.assessment_detail.valid?

        if !assessment_valid || !assessment_detail_valid
          errors.push(*assessment.assessment_detail&.errors&.errors)
          errors.push(*assessment.errors&.errors)
        end
      end

      return { errors: errors } if errors.any?

      # Save all assessments
      assessments.each do |assessment|
        # We need to call save on the processor directly to get the before_save hook to invoke.
        # If this is removed, the Enrollment won't save.
        assessment.assessment_detail.assessment_processor.save!
        # Save AssessmentDetail to save the rest of the related records
        assessment.assessment_detail.save!
        # Save the assessment as non-WIP
        assessment.save_not_in_progress
        # If this is an intake assessment, ensure the enrollment is no longer in WIP status
        assessment.enrollment.save_not_in_progress if assessment.intake?
        # Update DateUpdated on the Enrollment
        assessment.enrollment.touch
      end

      {
        assessments: assessments,
        errors: [],
      }
    end
  end
end
