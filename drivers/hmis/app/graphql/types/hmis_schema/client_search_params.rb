# frozen_string_literal: true

module Types
  class HmisSchema::ClientSearchParams < Types::BaseObject
    # underlying object is a Hmis::ClientSearchQuery

    field :id, ID, null: false

    # used for all use-cases that support free-text search:
    field :text_search, String, null: true

    # only used by advanced client search:
    field :personal_id, String, null: true
    field :first_name, String, null: true
    field :last_name, String, null: true
    field :ssn_serial, String, null: true
    field :dob, String, null: true

    [:text_search, :personal_id, :first_name, :last_name, :ssn_serial, :dob].each do |attr_name|
      define_method attr_name do
        object.params[attr_name.to_s]
      end
    end
  end
end
