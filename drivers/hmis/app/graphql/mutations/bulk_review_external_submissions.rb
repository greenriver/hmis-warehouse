###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class BulkReviewExternalSubmissions < CleanBaseMutation
    argument :external_submission_ids, [ID], required: true
    field :success, Boolean, null: true

    def resolve(external_submission_ids:)
      submissions = HmisExternalApis::ExternalForms::FormSubmission.where(id: external_submission_ids)
      definitions = Hmis::Form::Definition.where(id: submissions.pluck(:definition_id))

      # Submissions could come from different definitions (versions), but should be all the same form identifier
      identifiers = definitions.pluck(:identifier).uniq
      error_out('Cannot bulk process submissions from multiple form identifiers: ' + identifiers.inspect) unless identifiers.one?

      project = submissions.first.parent_project # can check first submission because we know they all have the same form identifier

      access_denied! unless current_permission?(permission: :can_manage_external_form_submissions, entity: project)
      access_denied! if definitions.any?(&:updates_client_or_enrollment?) && !current_permission?(permission: :can_edit_enrollments, entity: project)

      should_auto_enter = project.should_auto_enter?

      # maps record IDs to error messages
      failed_to_review = {}

      submissions.each do |record|
        raise ArgumentError, 'Already reviewed' if record.enrollment_id.present? || record.status == 'reviewed'

        record.status = 'reviewed'
        record.run_form_processor(current_user, project: project)

        if record.enrollment&.new_record?
          raise ArgumentError, record.enrollment.client.errors.full_messages unless record.enrollment.client.valid?
          raise ArgumentError, record.enrollment.errors.full_messages unless record.enrollment.valid?

          record.enrollment.client.save!
          should_auto_enter ? record.enrollment.save_and_auto_enter! : record.enrollment.save_in_progress!
        end

        record.form_processor.save!
        record.save!
      rescue StandardError => e
        failed_to_review[record.id] = e.message
      end

      if failed_to_review.any?
        base_message = "Bulk review failed on #{failed_to_review.size} of #{submissions.size} records."
        error_message = base_message + "\n" + failed_to_review.map { |id, message| "\tSubmission #{id}: #{message}" }.join("\n")
        display_message = base_message + ' This may indicate that the following submissions are spam, or have already been reviewed: ' + failed_to_review.keys.join(', ')
        raise HmisErrors::ApiError.new(error_message, display_message: display_message)
      end

      { success: true }
    end
  end
end
