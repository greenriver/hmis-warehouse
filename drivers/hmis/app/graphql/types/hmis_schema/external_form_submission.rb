###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class HmisSchema::ExternalFormSubmission < Types::BaseObject
    include Types::HmisSchema::HasCustomDataElements

    available_filter_options do
      arg :status, HmisSchema::Enums::ExternalFormSubmissionStatus
      arg :include_spam, Boolean
      arg :submitted_date, GraphQL::Types::ISO8601Date
    end

    field :id, ID, null: false
    field :submitted_at, GraphQL::Types::ISO8601DateTime, null: false
    field :spam, Boolean, null: true
    field :status, HmisSchema::Enums::ExternalFormSubmissionStatus, null: false
    field :notes, String, null: true
    field :definition, Forms::FormDefinition, null: false
    field :values, GraphQL::Types::JSON, null: true
    custom_data_elements_field # Resolve for backwards compatibility. Can remove in a future release

    def definition
      load_ar_association(object, :definition)
    end

    def values
      # Unlike CustomAssessments, which display on the frontend using the created CDEs once they've been submitted,
      # ExternalFormSubmissions always display using the values from raw_data. Example: If the form processor created
      # a client, and then a user manually updates the client's name in HMIS, the form review UI should still display
      # the client name that was originally submitted with the form.
      object.form_values
    end
  end
end
