###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::ExternalFormSubmission < Types::BaseObject
    include Types::HmisSchema::HasCustomDataElements

    available_filter_options do
      arg :status, [String]
    end

    field :id, ID, null: false
    field :submitted_at, GraphQL::Types::ISO8601DateTime, null: false
    field :spam_score, Float, null: true
    field :status, String, null: false # probably should be an enum to new | resolved
    field :notes, String, null: true
    field :definition, Forms::FormDefinition, null: false
    custom_data_elements_field

    def custom_data_elements
      definition_scope = Hmis::Hud::CustomDataElementDefinition.
        for_type(definition.external_form_submission_data_element_owner_type)

      resolve_custom_data_elements(object, definition_scope: definition_scope)
    end

    def definition
      load_ar_association(object, :definition)
    end
  end
end
