###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

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
      dob: Date.new(2000, 1, 1),
      email: 'no-reply@example.com',
      phone: '212-555-0100',
      geo_street: 'Street%{id}',
      geo_postal_code: '00000',
    }.freeze

    def self.static_value(field)
      raise "can't scrub required field '#{field.description}" unless STATIC_TYPE_VALUES.key?(field.type)

      format(TYPES_VALUES[field.type], id: record.id)
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
