###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class UpdateExternalFormSubmission < CleanBaseMutation
    argument :input, Types::HmisSchema::ExternalFormSubmissionInput, required: true
    argument :id, ID, required: true
    argument :project_id, ID, required: false # not required for backwards compatibility

    field :external_form_submission, Types::HmisSchema::ExternalFormSubmission, null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false, resolver: Resolvers::ValidationErrors

    def resolve(id:, project_id:, input:)
      record = HmisExternalApis::ExternalForms::FormSubmission.find(id)
      access_denied! unless allowed?(permissions: [:can_manage_external_form_submissions])

      record.assign_attributes(**input.to_params)

      errors = HmisErrors::Errors.new

      unless record.valid?
        errors.add_ar_errors(record.errors&.errors)
        return { errors: errors }
      end

      if record.status_changed? && record.status == 'reviewed' && !record.spam
        project = Hmis::Hud::Project.viewable_by(current_user).find_by(id: project_id)
        access_denied! unless project

        if record.definition.creates_client_or_enrollment?
          access_denied! unless current_permission?(permission: :can_edit_enrollments, entity: project)
        end

        record.run_form_processor(project, current_user)

        Hmis::Hud::Base.transaction do
          if record.enrollment&.new_record?
            # Raise with user-facing error message so that we get notified (rather than returning errors in the response body)
            error_out(record.enrollment.client.errors.full_messages) unless record.enrollment.client.valid?
            error_out(record.enrollment.errors.full_messages) unless record.enrollment.valid?

            record.enrollment.client.save!
            record.enrollment.save_new_enrollment!
          end
          record.form_processor.save!
          record.save!
        end
      else
        record.save!
      end

      {
        external_form_submission: record,
        errors: errors,
      }
    end

    protected

    def error_out(msg)
      raise HmisErrors::ApiError.new(msg, display_message: 'Unable to process form submission due to invalid values. Contact your administrator if the problem persists.')
    end
  end
end
