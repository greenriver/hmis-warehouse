###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ==  Mutations::SubmitAssessment
#
# This mutation creates or updates a custom assessment, form processor, and related HUD records.
#
# Steps:
# 1) Assessment Identification and Creation:
#    - If an assessment_id is provided, find the corresponding CustomAssessment.
#    - If no assessment_id is provided, a new CustomAssessment is created based on the form_definition and enrollment. A form processor is instantiated and associated with the assessment.
#
# 2) Field Processing:
#    - Each hud_value field is on the assessment input processed.
#    - A specific Field-Processor class is located for each field using a "containers" mapping.
#    - The Field-Processor.process method is called for each (field, value) pair.
#
# 3) Field-Processor Operation:
#    - Each field-processor calls back to the form_processor to retrieve a "factory" which is an active record model.
#    - This factory model could be associated with the enrollment or just the the form_processor
#    - The form values are assigned to the factory model but are not persisted at this point
#
# 4) Post field-processing Validation:
#    - The mutation validates the assessment and returns early if errors are found.
#
# 5) Save Submitted Assessment if Valid:
#    - Persists the form processor and attributes assigned to the related factory models
#    - After save it also handles conditional hard-coded side-effects and related integrations (LINK, etc).
#
module Mutations
  class SubmitAssessment < BaseMutation
    description 'Create/Submit assessment, and create/update related HUD records'

    argument :input, Types::HmisSchema::AssessmentInput, required: true
    argument :assessment_lock_version, Integer, required: false

    field :assessment, Types::HmisSchema::Assessment, null: true

    def resolve(input:, assessment_lock_version: nil)
      # assessment is a Hmis::Hud::CustomAssessment
      assessment, errors = input.find_or_create_assessment
      return { errors: errors } if errors.any?

      assessment.lock_version = assessment_lock_version if assessment_lock_version
      enrollment = assessment.enrollment

      errors = HmisErrors::Errors.new

      # FIXME: several of the below errors are duplicative of SubmitHouseholdAssessments error checks. They should be moved into the CustomAssessmentValidator instead.

      has_already_been_submitted = assessment.persisted? && !assessment.in_progress?

      # HoH Exit constraints
      if enrollment.head_of_household? && assessment.exit? && !has_already_been_submitted
        open_enrollments = Hmis::Hud::Enrollment.open_on_date(Date.tomorrow). # if other members exited today, its OK
          viewable_by(current_user).
          where(household_id: enrollment.household_id).
          where.not(id: enrollment.id)

        # Error: cannot exit HoH if there are any other open enrollments
        errors.add :assessment, :invalid, full_message: 'Cannot exit head of household because there are existing open enrollments. Please assign a new HoH.' if open_enrollments.any?
      end

      # Non-HoH Intake constraints
      if !enrollment.head_of_household? && assessment.intake? && !has_already_been_submitted
        hoh_enrollment = Hmis::Hud::Enrollment.open_on_date(Date.tomorrow). # if HoH entered today, it's OK
          heads_of_households.
          viewable_by(current_user).
          where(household_id: enrollment.household_id).
          first

        # Error: HoH intake is WIP, so this assessment cannot be submitted yet
        errors.add :assessment, :invalid, full_message: 'Cannot submit intake assessment because the Head of Household\'s intake has not yet been completed.' if hoh_enrollment&.in_progress?
      end

      errors.add :assessment, :invalid, full_message: 'Cannot exit an incomplete enrollment. Please complete the entry assessment first.' if assessment.exit? && enrollment.in_progress?
      return { errors: errors } if errors.any?

      # Update values
      assessment.form_processor.assign_attributes(
        values: input.values,
        hud_values: input.hud_values,
      )
      assessment.assign_attributes(
        user_id: hmis_user.user_id,
        assessment_date: assessment.form_processor.find_assessment_date_from_values,
      )

      # Validate form values based on FormDefinition
      form_validations = assessment.form_processor.collect_form_validations
      errors.push(*form_validations)

      # Run processor to create/update related records
      assessment.form_processor.run!(user: current_user)

      # Run validations
      is_valid = assessment.valid?(:form_submission)

      # Collect validations and warnings from AR Validator classes
      record_validations = assessment.form_processor.collect_record_validations(user: current_user)
      errors.push(*record_validations)

      errors.drop_warnings! if input.confirmed
      errors.deduplicate!
      return { errors: errors } if errors.any?

      return { assessments: assessments, errors: [] } if input.validate_only

      if is_valid
        assessment.save_submitted_assessment!(current_user: current_user)
      else
        # These are potentially unfixable errors. Maybe should be server error instead.
        # For now, return them all because they are useful in development.
        errors.add_ar_errors(assessment.form_processor&.errors&.errors)
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
