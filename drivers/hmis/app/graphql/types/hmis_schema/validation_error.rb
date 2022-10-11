###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::ValidationError < Types::BaseObject
    field :id, String, null: true
    field :attribute, String, null: true
    field :message, String, null: false
    field :full_message, String, null: true
    field :type, String, null: false
    field :options, JsonObject, null: true

    def attribute
      return object.attribute.to_s.underscore.camelize(:lower) if object.respond_to?(:attribute)
    end

    def options
      return object.options if object.respond_to?(:options)
    end

    def id
      return object.id if object.respond_to?(:id)
    end

    def full_message
      return object.full_message if object.respond_to?(:full_message)
    end

    def type
      return object.type if object.respond_to?(:type)
      return object.class.name if object.is_a?(Exception)

      'UnknownError'
    end
  end
end
