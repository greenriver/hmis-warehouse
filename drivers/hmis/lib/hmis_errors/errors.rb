###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisErrors
  class Errors
    include Enumerable

    extend Forwardable
    def_delegators :@errors, :size, :clear, :blank?, :empty?, :uniq!, :any?, :count, :push, :all?
    attr_reader :errors
    alias objects errors

    def initialize
      @errors = []
    end

    def add_ar_errors(errors, ignore_duplicates: true)
      Array.wrap(errors).each do |ar_error|
        hmis_error = HmisErrors::Error.from_ar_error(ar_error)
        next if ignore_duplicates && @errors.find { |e| self.class.errors_are_equal(e, hmis_error) }

        @errors << hmis_error
      end
      @errors
    end
    alias add_ar_error add_ar_errors

    def add(attribute, type = :invalid, **options)
      error = HmisErrors::Error.new(attribute, type, **options)
      @errors.append(error)
      error
    end

    def add_with_record_id(errors, record_id)
      Array.wrap(errors).each do |e|
        e.send(:define_singleton_method, :record_id) { record_id }
        @errors << e
      end
      @errors
    end

    def drop_warnings!
      @errors = @errors.reject(&:warning?)
    end

    def deduplicate!
      @errors = @errors.uniq { |e| [e.attribute.to_s.downcase, e.type.to_sym, e.severity, e.full_message.downcase, e.record_id] }
    end

    def self.errors_are_equal(first, second)
      first.attribute.to_s == second.attribute.to_s &&
      first.type.to_sym == :required && second.type.to_sym == :required
    end
  end
end
