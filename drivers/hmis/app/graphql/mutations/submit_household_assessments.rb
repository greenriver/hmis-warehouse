###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class SubmitHouseholdAssessments < BaseMutation
    description 'Submit multiple assessments in a household'

    argument :submissions, [Types::HmisSchema::VersionedRecordInput], required: true
    argument :confirmed, Boolean, 'Whether warnings have been confirmed', required: false
    argument :validate_only, Boolean, 'Validate assessments but don\'t submit them', required: false

    field :assessments, [Types::HmisSchema::Assessment], null: true

    def resolve(submissions:, confirmed:, validate_only: false)
      submissions_by_id = submissions.index_by(&:id)
      assessments = Hmis::Hud::CustomAssessment.viewable_by(current_user).
        where(id: submissions_by_id.keys).
        preload(:enrollment, :form_processor).to_a

      # Error: not all assessments found
      raise 'Assessments not found' if assessments.count != submissions.size

      # setup optimistic locking
      assessments.each do |assessment|
        lock_version = submissions_by_id[assessment.id.to_s].lock_version
        assessment.lock_version = lock_version if lock_version
      end

      enrollments = assessments.map(&:enrollment)

      # Error: insufficient permissions
      raise 'Insufficient permissions' unless current_user.permissions_for?(enrollments.first, :can_edit_enrollments)

      # Error: assessments do not all belong to the same household
      household_ids = enrollments.map(&:household_id).uniq
      raise "Assessments must all belong to the same household. #{household_ids}" if household_ids.count != 1

      # Error: assessments do not have the same data collection stage
      data_collection_stages = assessments.map(&:data_collection_stage).uniq
      raise "Assessments must have the same data collection stage. #{data_collection_stages}" if data_collection_stages.count != 1

      is_exit = assessments.first.exit?
      is_intake = assessments.first.intake?
      includes_hoh = enrollments.map(&:relationship_to_ho_h).uniq.include?(1)

      household_enrollments_not_included = enrollments.first.household_members.where.not(enrollment_id: enrollments.map(&:enrollment_id))

      # FIXME: several of the below errors are duplicative of SubmitAssessment error checks. They should be moved into the CustomAssessmentValidator instead.
      errors = HmisErrors::Errors.new

      # HoH Exit constraints
      if is_exit && includes_hoh
        # "Date.tomorrow" because it's OK if the exit date is today, but not if there is no exit date, or if the exit date is in the future (shouldn't happen)
        open_enrollments = household_enrollments_not_included.open_on_date(Date.tomorrow)

        # Error: cannot exit HoH if there are any other open enrollments
        errors.add :assessment, :invalid, full_message: 'Cannot exit head of household because there are existing open enrollments. Please assign a new HoH, or exit all open enrollments.' if open_enrollments.any?
      end

      # Error: WIP enrollments cannot be exited
      errors.add :assessment, :invalid, full_message: 'Cannot exit incomplete enrollments. Please complete entry assessments first.' if is_exit && enrollments.any?(&:in_progress?)

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
        form_validations = assessment.form_processor.collect_form_validations
        errors.add_with_record_id(form_validations, assessment.id)
      end

      # Run form processor on each assessment to create/update related records
      assessments.each do |assessment|
        assessment.assign_attributes(user_id: hmis_user.user_id)
        assessment.form_processor.run!(user: current_user)
      end

      # Collect validations (hmis_validate and AR validation)
      all_valid = true
      household_members = assessments.map(&:enrollment) # Enrollments with unsaved changes to Entry dates
      assessments.each do |assessment|
        all_valid = false unless assessment.valid?(:form_submission)
        record_validations = assessment.form_processor.collect_record_validations(
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
          errors.add_ar_errors(assessment.form_processor&.errors&.errors)
          errors.add_ar_errors(assessment.errors&.errors)
        end
        return { errors: errors }
      end

      # Save all assessments and related records
      Hmis::Hud::CustomAssessment.transaction do
        assessments.each do |a|
          a.save_submitted_assessment!(current_user: current_user)
        end
      end

      {
        assessments: assessments,
        errors: [],
      }
    end
  end
end
