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
        next if record.enrollment_id.present? || record.status == 'reviewed'

        begin
          record.run_form_processor(current_user, project: project)
        rescue RuntimeError => e
          # if there was an unexpected error running the form processor, it could mean the form response was malformed.
          # catch this error so that it doesn't cause the whole bulk batch to fail.
          failed_to_review[record.id] = e.message
          next
        end

        if record.enrollment&.new_record?
          unless record.enrollment.client.valid?
            failed_to_review[record.id] = record.enrollment.client.errors.full_messages
            next
          end

          unless record.enrollment.valid?
            failed_to_review[record.id] = record.enrollment.errors.full_messages
            next
          end

          record.enrollment.client.save!
          should_auto_enter ? record.enrollment.save_and_auto_enter! : record.enrollment.save_in_progress!
        end

        record.form_processor.save!

        record.status = 'reviewed'
        record.save!
      end

      if failed_to_review.any?
        base_message = "Bulk review failed on #{failed_to_review.size} of #{submissions.size} records."
        error_message = base_message + "\n" + failed_to_review.map { |id, message| "\tSubmission #{id}: #{message}" }.join("\n")
        display_message = base_message + ' This may indicate that the following submissions are spam: ' + failed_to_review.keys.join(', ')

        # Raise, instead of returning a ValidationError, so we will get notified in Sentry, since either a bug with
        # our implementation or an influx of spam would be interesting for us to get notified about.
        # If this gets extremely noisy due to spam, we might be tempted to turn off the Sentry error and return a
        # ValidationError instead. If we do that, we should take care to *keep* Sentry errors on for invalid
        # client/enrollment errors (that would indicate an implementation problem and not bad/spammy data).
        raise HmisErrors::ApiError.new(error_message, display_message: display_message)
      end

      { success: true }
    end
  end
end
