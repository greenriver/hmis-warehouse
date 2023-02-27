###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisErrors
  class Errors
    include Enumerable

    extend Forwardable
    def_delegators :@errors, :size, :clear, :blank?, :empty?, :uniq!, :any?, :count
    attr_reader :errors
    alias objects errors

    def initialize
      @errors = []
    end

    def add_ar_errors(errors)
      Array.wrap(errors).each do |ar_error|
        @errors << HmisErrors::Error.from_ar_error(ar_error)
      end
      @errors
    end
    alias add_ar_error add_ar_errors

    def add(attribute, type = :invalid, **options)
      error = HmisErrors::Error.new(attribute, type, **options)
      @errors.append(error)
      error
    end
  end
end
