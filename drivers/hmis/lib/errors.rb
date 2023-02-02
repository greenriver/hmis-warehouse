###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Errors
  class CustomValidationError
    def initialize(attribute, type = :invalid, message: nil, full_message: nil, severity: :error, **kwargs)
      {
        attribute: attribute,
        type: type,
        message: message,
        full_message: full_message,
        severity: severity,
        **kwargs,
      }.each do |key, value|
        define_singleton_method(key) { value }
      end
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
