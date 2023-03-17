###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisErrors
  class Error
    def initialize(attribute, type = :invalid, severity: :error, message: nil, full_message: nil, readable_attribute: nil, **kwargs)
      type = :invalid unless Types::HmisSchema::Enums::ValidationType.values.keys.include?(type.to_s)

      # Camelize attribute ("entryDate" not "entry_date")
      attribute = attribute.to_s.underscore.camelize(:lower).to_sym
      # Create readable attribute ("Entry date")
      readable_attribute ||= self.class.humanize_attribute(attribute)

      # Set default message and full message
      message ||= self.class.default_message_for_type(type)
      full_message ||= "#{readable_attribute} #{message}"

      {
        attribute: attribute,
        type: type.to_sym,
        message: message,
        full_message: full_message,
        readable_attribute: readable_attribute,
        severity: severity,
        id: nil,
        record_id: nil,
        link_id: nil,
        section: nil,
        **kwargs,
      }.each do |key, value|
        define_singleton_method(key) { value }
      end
    end

    def self.from_ar_error(error)
      error = error.inner_error if error.is_a? ActiveModel::NestedError

      # 'must exist' string as type: https://github.com/rails/rails/blob/83217025a171593547d1268651b446d3533e2019/activemodel/lib/active_model/error.rb#L65
      type = [:blank, 'must exist'].include?(error.type) ? :required : error.type
      readable_attribute = humanize_attribute(error.attribute)
      full_message = error.options[:full_message] || error.full_message&.gsub(error.attribute.to_s.downcase.capitalize, readable_attribute)

      new(
        error.attribute,
        type,
        message: error.message,
        full_message: full_message,
        readable_attribute: readable_attribute,
        severity: :error,
        record_id: error.object_id,
      )
    end

    def to_h
      singleton_methods(false).map { |m| [m, send(m)] }.to_h
    end

    def warning?
      severity&.to_sym == :warning
    end

    def self.humanize_attribute(attribute)
      attribute.to_s.underscore.humanize
    end

    def self.default_message_for_type(err_type)
      case err_type.to_sym
      when :data_not_collected
        'is empty'
      when :not_found
        'not found'
      when :not_allowed
        'operation not allowed'
      when :server_error
        'failed to validate due to a server error'
      else
        I18n.t("errors.messages.#{err_type}", default: 'is invalid')
      end
    end
  end
end
