###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::ExternalFormSubmission < Types::BaseObject
    include Types::HmisSchema::HasCustomDataElements

    field :id, ID, null: false
    field :submitted_at, GraphQL::Types::ISO8601DateTime, null: false
    field :spam_score, Float, null: true
    field :status, String, null: false # probably should be an enum to new | resolved
    field :notes, String, null: true
    field :custom_data_elements, [Types::HmisSchema::CustomDataElement], null: false
  end
end
