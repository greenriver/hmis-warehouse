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

    field :external_form_submission, Types::HmisSchema::ExternalFormSubmission, null: false
    field :errors, [Types::HmisSchema::ValidationError], null: false, resolver: Resolvers::ValidationErrors

    def resolve(id:, project_id:, input:)
      record = HmisExternalApis::ExternalForms::FormSubmission.find(id)
      raise 'Access denied' unless allowed?(permissions: [:can_manage_external_form_submissions])

      record.assign_attributes(**input.to_params)

      errors = []

      if record.status == 'reviewed' && !record.spam
        definition = record.definition

        # Only if there are Client and/or Enrollment fields in the form definition, initialize an enrollment
        # (which will in turn initialize a Client, inside the form processor).
        if definition.link_id_item_hash.values.find { |item| ['ENROLLMENT', 'CLIENT'].include?(item.mapping.record_type) }
          # todo @Martha - do we need to check for additional permissions here, like can manage clients/enrollments?
          project = Hmis::Hud::Project.find(project_id)
          record.build_enrollment(project: project, data_source: project.data_source, entry_date: record.created_at)
        end

        form_processor = record.form_processor || record.build_form_processor(definition: definition)

        form_processor.values = record.raw_data
        form_processor.hud_values = input.hud_values

        # todo @Martha - validations see submit_form.rb
        # form_validations = form_processor.collect_form_validations
        # errors.push(*form_validations)

        form_processor.run!(user: current_user)

        # record_validations = form_processor.collect_record_validations(user: current_user)
        # errors.push(*record_validations)

        form_processor.save! # saves related records so maybe the above is not needed?

        # todo @martha - transaction
        if record.enrollment
          record.enrollment.client.save!
          record.enrollment.save_new_enrollment!
        end
      end

      if record.valid?
        record.save! # todo @Martha don't need to save again
      else
        errors = record.errors
        record = nil
      end

      {
        external_form_submission: record,
        errors: errors,
      }
    end
  end
end
