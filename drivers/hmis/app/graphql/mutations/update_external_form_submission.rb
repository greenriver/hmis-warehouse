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

      # todo @martha - household can of worms
      if record.status == 'reviewed' # and not spam!

        # right now there is no way to pass enrollment (or project, or data source?) directly to the form processor
        # see submit_form permission_base_and_record for similar pattern. we create enrollment here in the mutation
        project = Hmis::Hud::Project.find(project_id)
        enrollment = Hmis::Hud::Enrollment.new
        enrollment.project = project
        enrollment.entry_date = record.created_at

        form_processor = record.form_processor || record.build_form_processor(definition: record.definition)
        form_processor.values = record.raw_data

        # todo @martha - how to make more generic, this is only for pit
        form_processor.hud_values = {
          # "Enrollment.EntryDate": record.created_at,
          # "Enrollment.ProjectID": project_id,
          # "Client.firstName": "three",
          # "Client.lastName": "four",
        }.merge(record.raw_data) # todo @martha - any other values to include?

        # form_validations = form_processor.collect_form_validations
        # errors.push(*form_validations)

        form_processor.run!(user: current_user)

        # need validation see submit_form.rb
        # record_validations = form_processor.collect_record_validations(user: current_user)
        # errors.push(*record_validations)

        record.save!
        form_processor.save! # saves related records so maybe the above is not needed?
        # save in transaction?
      end

      if record.valid?
        record.save!
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
