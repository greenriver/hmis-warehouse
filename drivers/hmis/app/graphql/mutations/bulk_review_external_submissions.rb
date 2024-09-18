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

      already_reviewed = submissions.filter { |s| s.enrollment_id.present? || s.status == 'reviewed' }
      error_out('Submissions are already processed: ' + already_reviewed.pluck(:id).inspect) if already_reviewed.any?

      should_auto_enter = project.should_auto_enter?

      HmisExternalApis::ExternalForms::FormSubmission.transaction do
        submissions.each do |record|
          record.status = 'reviewed'
          record.run_form_processor(current_user, project: project)

          if record.enrollment&.new_record?
            error_out(record.enrollment.client.errors.full_messages) unless record.enrollment.client.valid?
            error_out(record.enrollment.errors.full_messages) unless record.enrollment.valid?

            record.enrollment.client.save!
            should_auto_enter ? record.enrollment.save_and_auto_enter! : record.enrollment.save_in_progress!
          end

          record.form_processor.save!
          record.save!
        end
      end

      { success: true }
    end

    protected

    def error_out(msg)
      raise HmisErrors::ApiError.new(msg, display_message: 'Unable to process bulk review action. Contact your administrator if the problem persists.')
    end
  end
end
