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
    field :readable_attribute, String, null: true
    field :message, String, null: false
    field :full_message, String, null: false
    field :type, HmisSchema::Enums::ValidationType, null: false
    field :severity, HmisSchema::Enums::ValidationSeverity, null: false
    field :options, JsonObject, null: true

    def attribute
      object.attribute.to_s.underscore.camelize(:lower) if object.respond_to?(:attribute)
    end

    # Converts 'operatingStartDate' => 'Operating start date'
    # Converts 'organizationId' => 'Organization'
    def readable_attribute
      return object.readable_attribute if object.respond_to?(:readable_attribute) && object.readable_attribute.present?

      object.attribute.to_s.underscore.humanize if object.respond_to?(:attribute) && object.attribute.present?
    end

    def options
      object.options if object.respond_to?(:options)
    end

    def id
      object.id if object.respond_to?(:id)
    end

    def message
      return object.message if object.respond_to?(:message) && object.message.present?

      return 'is empty' if type == 'data_not_collected'

      return 'not found' if type == 'not_found'

      I18n.t("errors.messages.#{type}", default: 'is invalid')
    end

    def full_message
      return object.full_message.gsub(object.attribute.to_s.downcase.capitalize, readable_attribute) if object.respond_to?(:full_message) && object.full_message.present?
      return "#{readable_attribute} #{message}" if readable_attribute.present?
      return "#{attribute} #{message}" if attribute.present?

      'An unknown error occurred'
    end

    def type
      if object.respond_to?(:type) && object.type.present?
        return 'required' if object.type == :blank
        # https://github.com/rails/rails/blob/83217025a171593547d1268651b446d3533e2019/activemodel/lib/active_model/error.rb#L65
        return 'required' if object.type == 'must exist'

        return object.type.to_s if Types::HmisSchema::Enums::ValidationType.values.keys.include?(object.type.to_s)
      end

      return 'server_error' if object.is_a?(Exception)

      'invalid'
    end

    def severity
      return object.severity.to_s if object.respond_to?(:severity) && Types::HmisSchema::Enums::ValidationSeverity.values.keys.include?(object.severity.to_s)

      'error'
    end
  end
end
