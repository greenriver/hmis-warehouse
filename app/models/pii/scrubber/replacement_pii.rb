###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'faker'

# helper for generating static / fake values for the PII scrubbers
module Pii::Scrubber
  class ReplacementPii
    attr_accessor :max_level

    STATIC_TYPE_VALUES = {
      first_name: 'FirstName%{id}',
      middle_name: 'MiddleName%{id}',
      last_name: 'LastName%{id}',
      full_name: 'FullName%{id}',
      ssn: '999000000',
      email: 'no-reply@example.com',
      phone: '2125550100',
      geo_street: 'Street%{id}',
      geo_postal_code: '00000',
    }.freeze

    def self.static_type?(field)
      field.type == :dob || STATIC_TYPE_VALUES.key?(field.type)
    end

    # nil when a dob can't be parsed
    def self.static_value(field, id:)
      raise "can't scrub required field '#{field.description}'" unless static_type?(field)
      return rounded_dob(field.real_value) if field.type == :dob

      format(STATIC_TYPE_VALUES[field.type], id: id)
    end

    # January 1 of the nearest birth year divisible by 5, rounded down when that would be in the future
    def self.rounded_dob(value)
      dob = parse_date(value)
      return unless dob

      rounded = Date.new((dob.year / 5.0).round * 5, 1, 1)
      rounded > Date.current ? rounded - 5.years : rounded
    end

    # HMIS CSV loader tables store DOB as a YYYY-MM-DD string
    def self.parse_date(value)
      return value unless value.is_a?(String)

      Date.strptime(value, '%Y-%m-%d')
    rescue ArgumentError
      nil
    end

    def self.fake_value(field)
      case field.type
      when :ssn
        # use 999 to make it more obvious the ssn is invalid
        Faker::IdNumber.invalid.gsub(/^\d{3}/, '999').gsub('-', '')
      when :first_name
        Faker::Name.first_name
      when :last_name
        Faker::Name.last_name
      when :middle_name
        Faker::Name.middle_name
      when :full_name
        Faker::Name.name
      end
    end
  end
end
