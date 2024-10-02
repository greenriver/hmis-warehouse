#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

module Mutations
  class DeleteExternalFormSubmission < CleanBaseMutation
    argument :id, ID, required: true

    field :external_form_submission, Types::HmisSchema::ExternalFormSubmission, null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false, resolver: Resolvers::ValidationErrors

    def resolve(id:)
      record = HmisExternalApis::ExternalForms::FormSubmission.find(id)
      project = record.parent_project
      access_denied! unless current_permission?(permission: :can_manage_external_form_submissions, entity: project)

      record.with_lock do
        # destroy related records on form processor (does NOT include Enrollment and Client)
        record.form_processor&.destroy_related_records!
        record.destroy!
      end

      {
        external_form_submission: record,
        errors: [],
      }
    end
  end
end
