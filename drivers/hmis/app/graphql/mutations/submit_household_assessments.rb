###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

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

      is_exit = assessments.first.exit?
      is_intake = assessments.first.intake?
      includes_hoh = enrollments.map(&:relationship_to_ho_h).uniq.include?(1)

      household_enrollments_not_included = enrollments.first.household_members.where.not(enrollment_id: enrollments.map(&:enrollment_id))

      # HoH Exit constraints
      if is_exit && includes_hoh
        # "Date.tomorrow" because it's OK if the exit date is today, but not if there is no exit date, or if the exit date is in the future (shouldn't happen)
        open_enrollments = household_enrollments_not_included.open_on_date(Date.tomorrow)

        # Error: cannot exit HoH if there are any other open enrollments
        errors.add :assessment, :invalid, full_message: 'Cannot exit head of household because there are existing open enrollments. Please assign a new HoH, or exit all open enrollments.' if open_enrollments.any?

        # Error: WIP enrollments cannot be exited
        errors.add :assessment, :invalid, full_message: 'Cannot exit incomplete enrollments. Please complete entry assessments first.' if enrollments.any?(&:in_progress?)
      end

      # Non-HoH Intake constraints
      if is_intake && !includes_hoh
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
        form_validations = assessment.custom_form.collect_form_validations
        errors.add_with_record_id(form_validations, assessment.id)
      end

      # Run form processor on each assessment to create/update related records
      assessments.each do |assessment|
        assessment.assign_attributes(user_id: hmis_user.user_id)
        assessment.custom_form.form_processor.run!(owner: assessment, user: current_user)
      end

      # Collect validations (hmis_validate and AR validation)
      all_valid = true
      household_members = assessments.map(&:enrollment) # Enrollments with unsaved changes to Entry dates
      assessments.each do |assessment|
        all_valid = false unless assessment.valid?
        all_valid = false unless assessment.custom_form.valid?
        record_validations = assessment.custom_form.collect_record_validations(
          user: current_user,
          household_members: household_members,
        )
        errors.add_with_record_id(record_validations, assessment.id)
      end

      # Return any validation errors
      errors.drop_warnings! if confirmed
      errors.deduplicate!
      return { errors: errors } if errors.any?

      return { assessments: assessments, errors: [] } if validate_only

      unless all_valid
        assessments.each do |assessment|
          errors.add_ar_errors(assessment.custom_form&.errors&.errors)
          errors.add_ar_errors(assessment.errors&.errors)
        end
        return { errors: errors }
      end

      # Save all assessments and related records
      Hmis::Hud::CustomAssessment.transaction do
        assessments.each do |assessment|
          # Save CustomForm to save related records
          assessment.custom_form.save!
          # Save the Enrollment (doesn't get saved by the FormProcessor since they dont have a relationship)
          assessment.enrollment.save!
          # Save the assessment as non-WIP
          assessment.save_not_in_progress
          # If this is an intake assessment, ensure the enrollment is no longer in WIP status
          assessment.enrollment.save_not_in_progress if assessment.intake?
          # Update DateUpdated on the Enrollment
          assessment.enrollment.touch
        end
      end

      {
        assessments: assessments,
        errors: [],
      }
    end
  end
end
