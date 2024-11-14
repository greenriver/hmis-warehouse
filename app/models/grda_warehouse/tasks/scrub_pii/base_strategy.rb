###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'faker'

# replace attributes on client and related records
module GrdaWarehouse::Tasks::ScrubPii
  class BaseStrategy
    def client_attrs(client)
      not_null_attrs(client).merge(
        # fields to overwrite
        SSN: nil,
        SSNDataQuality: 99,
        FirstName: nil,
        MiddleName: nil,
        NameDataQuality: 99,
        LastName: nil,
        DOB: scramble_dob(client.dob),
        soundex_first: nil,
        soundex_last: nil,
        encrypted_FirstName: nil,
        encrypted_MiddleName: nil,
        encrypted_LastName: nil,
        encrypted_SSN: nil,
      )
    end

    def enrollment_attrs(enrollment)
      not_null_attrs(enrollment).merge(
        # fields to overwrite
        LastPermanentStreet: nil,
        LastPermanentCity: nil,
        LastPermanentState: nil,
        LastPermanentZIP: nil,
        AddressDataQuality: 99,
        last_locality: nil,
        last_zipcode: nil,
      )
    end

    def report_client_attrs(client)
      not_null_attrs(client).merge(
        age: client.dob ? today - scramble_dob(client.dob) : nil,
        first_name: nil,
        last_name: nil,
        name_quality: 99,
        ssn: nil,
        ssn_quality: 99
      )
    end

    protected

    def today
      @today ||= Date.current
    end

    # Scrambles a date of birth while preserving approximate age bracket of the original
    # For example, with a 5-year bracket, someone aged 32 will get a DOB corresponding to age 30-35.
    def scramble_dob(current, fuzz_years: 5)
      return nil unless current

      age_at_scrub = ((today - current) / 365.25).floor
      age_bracket = (age_at_scrub / fuzz_years) * fuzz_years # Creates brackets
      bracket_start = today - (age_bracket + fuzz_years).years
      bracket_end = today - age_bracket.years

      Faker::Date.between(from: bracket_start, to: bracket_end)
    end

    def not_null_attrs(record)
      raise ArgumentError unless record.is_a?(ActiveRecord::Base)

      result = {}
      record.class.columns.reject(&:null).each do |column|
        attr_name = column.name.to_sym
        result[attr_name] = record[attr_name]
      end
      result
    end
  end
end
