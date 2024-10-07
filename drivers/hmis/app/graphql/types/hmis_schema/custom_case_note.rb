###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CustomCaseNote < Types::BaseObject
    include Types::HmisSchema::HasHudMetadata
    include Types::HmisSchema::HasCustomDataElements

    description 'Case Note'
    field :id, ID, null: false
    field :enrollment, HmisSchema::Enrollment, null: false
    field :client, HmisSchema::Client, null: false
    field :content, String, null: false
    field :information_date, GraphQL::Types::ISO8601Date, null: true
    field :form_definition_id, ID, null: false
    custom_data_elements_field

    def enrollment
      load_ar_association(object, :enrollment)
    end

    def client
      load_ar_association(object, :client)
    end

    def form_definition_id
      load_ar_association(object, :form_processor)&.definition_id
    end
  end
end
