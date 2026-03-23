# frozen_string_literal: true

module Types
  class HmisSchema::SearchQuery < Types::BaseObject
    field :id, ID, null: false

    # used for all use-cases that support free-text search:
    field :text_search, String, null: true

    # only used by advanced client search:
    field :personal_id, String, null: true
    field :warehouse_id, String, null: true
    field :first_name, String, null: true
    field :last_name, String, null: true
    field :ssn_serial, String, null: true
    field :dob, String, null: true

    [:text_search, :personal_id, :warehouse_id, :first_name, :last_name, :ssn_serial, :dob].each do |field|
      define_method field do
        object.params[field.to_s]
      end
    end
  end
end
