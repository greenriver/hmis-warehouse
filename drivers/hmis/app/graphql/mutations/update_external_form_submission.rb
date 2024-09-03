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

    def _resolve(id:, project_id:, input:)
      record = HmisExternalApis::ExternalForms::FormSubmission.find(id)
      raise 'Access denied' unless allowed?(permissions: [:can_manage_external_form_submissions])

      record.assign_attributes(**input.to_params)

      errors = HmisErrors::Errors.new

      if record.status_changed? && record.status == 'reviewed' && !record.spam
        definition = record.definition

        # Only if there are Client and/or Enrollment fields in the form definition, initialize an enrollment
        # (which will in turn initialize a Client, inside the form processor).
        if definition.link_id_item_hash.values.find { |item| ['ENROLLMENT', 'CLIENT'].include?(item.mapping.record_type) }
          project = Hmis::Hud::Project.find(project_id)
          record.build_enrollment(project: project, data_source: project.data_source, entry_date: record.created_at)
        end

        form_processor = record.form_processor || record.build_form_processor(definition: definition)

        form_processor.values = record.cleaned_values
        form_processor.hud_values = input.hud_values

        # Validate based on form definition
        form_validations = form_processor.collect_form_validations
        errors.push(*form_validations)

        # Run to create CDEs, and client/enrollment if applicable
        form_processor.run!(user: current_user)

        # Collect validations and warnings from AR Validator classes
        record_validations = form_processor.collect_record_validations(user: current_user)
        errors.push(*record_validations)

        errors.deduplicate!
        return { errors: errors } if errors.any?

        if record.enrollment&.new_record?
          record.enrollment.client.save!
          record.enrollment.save_new_enrollment!
        end

        form_processor.save!
      end

      if record.valid?
        record.save!
      else
        # todo @martha! - how to arrange this? rollback transacction if record not valid
        # but record shoudl be saved if valid, whether form processor is present or not
        errors.add_ar_errors(record.errors&.errors)
        record = nil
      end

      {
        external_form_submission: record,
        errors: errors,
      }
    end
  end
end
