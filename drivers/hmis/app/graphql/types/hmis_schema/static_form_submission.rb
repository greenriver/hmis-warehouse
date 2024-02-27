###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::StaticFormSubmission < Types::BaseObject
    field :id, ID, null: false
    field :submitted_at, GraphQL::Types::ISO8601DateTime, null: false
    field :spam_score, Float, null: true
    field :status, String, null: false
    field :notes, String, null: true
    # tbd
    # field :name, String, null: false
    # field :fields
    # status enum?
  end
end
