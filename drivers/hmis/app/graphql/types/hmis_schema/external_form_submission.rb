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
      arg :submitted_date, GraphQL::Types::ISO8601Date
    end

    field :id, ID, null: false
    field :submitted_at, GraphQL::Types::ISO8601DateTime, null: false
    field :spam, Boolean, null: true
    field :status, HmisSchema::Enums::ExternalFormSubmissionStatus, null: false
    field :notes, String, null: true
    field :definition, Forms::FormDefinition, null: false
    custom_data_elements_field

    def custom_data_elements
      cdeds = load_ar_association(definition, :custom_data_element_definitions, scope: Hmis::Hud::CustomDataElementDefinition.order(:key))
      resolve_custom_data_elements(object, definition_scope: cdeds)
    end

    def definition
      load_ar_association(object, :definition)
    end
  end
end
