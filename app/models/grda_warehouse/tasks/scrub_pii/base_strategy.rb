###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'faker'

# replaces
module GrdaWarehouse::Tasks::ScrubPii
  class BaseStrategy
    def client_attrs(client)
      {
        # required non-nullable fields for upsert
        id: client.id,
        data_source_id: client.data_source_id,
        # fields to overwrite
        PersonalID: client.PersonalID,
        SSN: nil,
        SSNDataQuality: 99,
        FirstName: nil,
        MiddleName: nil,
        NameDataQuality: 99,
        LastName: nil,
        DOB: scramble_dob(client.dob),
        DOBDataQuality: client.dob ? 2 : 99,
        soundex_first: nil,
        soundex_last: nil,
        encrypted_FirstName: nil,
        encrypted_MiddleName: nil,
        encrypted_LastName: nil,
        encrypted_SSN: nil,
      }
    end

    def enrollment_attrs(enrollment)
      {
        # required non-nullable fields for upsert
        id: enrollment.id,
        data_source_id: enrollment.data_source_id,
        PersonalID: enrollment.PersonalID,
        EnrollmentID: enrollment.EnrollmentID,
        ProjectID: enrollment.ProjectID,
        EntryDate: enrollment.EntryDate,
        # fields to overwrite
        LastPermanentStreet: nil,
        LastPermanentCity: nil,
        LastPermanentState: nil,
        LastPermanentZIP: nil,
        AddressDataQuality: 99,
        last_locality: nil,
        last_zipcode: nil,
      }
    end

    protected

    def today
      @today ||= Date.current
    end

    def scramble_dob(current, fuzz_years: 5)
      return nil unless current

      age_at_scrub = ((today - current) / 365.25).floor
      age_bracket = (age_at_scrub / fuzz_years) * fuzz_years # Creates brackets
      bracket_start = today - (age_bracket + fuzz_years).years
      bracket_end = today - age_bracket.years

      Faker::Date.between(from: bracket_start, to: bracket_end)
    end
  end
end
