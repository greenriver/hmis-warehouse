# frozen_string_literal: true

module Types
  class HmisSchema::SearchQuery < Types::BaseObject
    field :id, ID, null: false
    field :params, JsonObject, null: false
  end
end
