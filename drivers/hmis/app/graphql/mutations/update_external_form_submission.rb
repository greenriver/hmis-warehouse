###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class UpdateExternalFormSubmission < CleanBaseMutation
    argument :input, Types::HmisSchema::ExternalFormSubmissionInput, required: true
    argument :id, ID, required: true

    field :external_form_submission, Types::HmisSchema::ExternalFormSubmission, null: false
    field :errors, [Types::HmisSchema::ValidationError], null: false, resolver: Resolvers::ValidationErrors

    def resolve(id:, input:)
      record = HmisExternalApis::ExternalForms::FormSubmission.find(id)
      raise 'Access denied' unless allowed?(permissions: [:can_manage_external_form_submissions])

      record.assign_attributes(**input.to_params)

      errors = []
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
