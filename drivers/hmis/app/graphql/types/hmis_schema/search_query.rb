# frozen_string_literal: true

module Types
  class HmisSchema::SearchQuery < Types::BaseObject
    field :id, ID, null: false
    field :params, JsonObject, null: false

    def params
      object.params.transform_keys { |k| k.camelize(:lower) }
    end
  end
end
