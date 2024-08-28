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
    field :values, GraphQL::Types::JSON, null: false

    def definition
      load_ar_association(object, :definition)
    end

    def values
      object.raw_data
    end
  end
end
