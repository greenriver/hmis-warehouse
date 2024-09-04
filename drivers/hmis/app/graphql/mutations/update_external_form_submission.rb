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

    def resolve(...)
      Hmis::Hud::Base.transaction do
        _resolve(...)
      end
    end

    protected

    def error_out(msg)
      raise HmisErrors::ApiError.new(msg, display_message: 'Unable to process form submission due to invalid values. Contact your administrator if the problem persists.')
    end

    def _resolve(id:, project_id:, input:)
      record = HmisExternalApis::ExternalForms::FormSubmission.find(id)
      raise 'Access denied' unless allowed?(permissions: [:can_manage_external_form_submissions])

      record.assign_attributes(**input.to_params)

      errors = HmisErrors::Errors.new

      unless record.valid?
        errors.add_ar_errors(record.errors&.errors)
        return { errors: errors }
      end

      if record.status_changed? && record.status == 'reviewed' && !record.spam
        definition = record.definition

        # Only if there are Client and/or Enrollment fields in the form definition, initialize an enrollment
        # (which will in turn initialize a Client, inside the form processor).
        if definition.link_id_item_hash.values.find { |item| ['ENROLLMENT', 'CLIENT'].include?(item.mapping.record_type) }
          project = Hmis::Hud::Project.viewable_by(current_user).find_by(id: project_id)

          access_denied! unless project
          access_denied! unless current_permission?(permission: :can_edit_enrollments, entity: project)

          record.build_enrollment(project: project, data_source: project.data_source, entry_date: record.created_at)
          # Assume that required values on Client and Enrollment (e.g. relationship to HoH) are present
          # and correctly mapped in raw_values. The form processor record validator will fail otherwise.
        end

        form_processor = record.form_processor || record.build_form_processor(definition: definition)

        form_processor.hud_values = record.form_values
        # We skip the form_processor.collect_form_validations step, because the external form has already been
        # submitted. If it's invalid, there is nothing the user can do about it now.
        # Also skip form_processor.collect_record_validations since e don't want to completely block from processing
        # if the external submission results in invalid values. We should process and allow correction after-the-fact.

        # Run to create CDEs, and client/enrollment if applicable
        form_processor.run!(user: current_user)

        errors.deduplicate!
        return { errors: errors } if errors.any?

        if record.enrollment&.new_record?
          # Raise with user-facing error message so that we get notified (rather than returning errors in the response body)
          error_out(record.enrollment.client.errors.full_messages) unless record.enrollment.client.valid?
          error_out(record.enrollment.errors.full_messages) unless record.enrollment.valid?

          record.enrollment.client.save!
          record.enrollment.save_new_enrollment!
        end

        form_processor.save!
      end

      record.save! # checked for validity above

      {
        external_form_submission: record,
        errors: errors,
      }
    end
  end
end
