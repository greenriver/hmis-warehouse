###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisErrors
  class CustomValidationError
    def initialize(attribute, type = :invalid, message: nil, full_message: nil, severity: :error, readable_attribute: nil, **kwargs)
      {
        attribute: attribute,
        type: type,
        message: message,
        full_message: full_message,
        readable_attribute: readable_attribute,
        severity: severity,
        **kwargs,
      }.each do |key, value|
        define_singleton_method(key) { value }
      end
    end

    def to_h
      {
        attribute: attribute,
        type: type,
        message: message,
        full_message: full_message,
        severity: severity,
        readable_attribute: readable_attribute,
      }
    end

    def warning?
      severity&.to_sym == :warning
    end
  end

  class CustomValidationErrors
    include Enumerable

    extend Forwardable
    def_delegators :@errors, :size, :clear, :blank?, :empty?, :uniq!, :any?, :count
    attr_reader :errors
    alias objects errors

    def initialize
      @errors = []
    end

    def add(attribute, type = :invalid, **options)
      error = CustomValidationError.new(attribute, type, **options)
      @errors.append(error)
      error
    end
  end
end
