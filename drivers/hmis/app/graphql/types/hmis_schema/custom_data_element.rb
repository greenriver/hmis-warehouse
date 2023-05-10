###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CustomDataElement < Types::BaseObject
    # object is an OpenStruct, see HasCustomDataElements

    field :id, ID, null: false
    field :key, String, null: true
    field :label, String, null: true
    field :value, HmisSchema::CustomDataElementValue, null: true
    field :values, [HmisSchema::CustomDataElementValue], null: true
    field :user, HmisSchema::User, null: true
    field :date_created, GraphQL::Types::ISO8601DateTime, null: false
    field :date_updated, GraphQL::Types::ISO8601DateTime, null: false

    def user
      load_ar_association(object.values&.first, :user)
    end

    def date_created
      object.values&.first&.date_created
    end

    def date_updated
      object.values&.first&.date_updated
    end

    # If this custom element only allows one value, 'value' is set
    def value
      return if object.repeats

      object.values.first
    end

    # If this custom element allows multiple values, 'values' is set (repeats: true)
    def values
      return unless object.repeats

      object.values
    end
  end
end
