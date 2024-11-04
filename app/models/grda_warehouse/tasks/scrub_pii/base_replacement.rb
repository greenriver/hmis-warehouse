
###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'faker'
module GrdaWarehouse::Tasks::ScrubPii < BaseReplacement
  class BaseReplacement

    def client_attrs(client)
      {
        SSN: nil,
        SSNDataQuality: 99,
        FirstName: nil,
        MiddleName: nil,
        NameDataQuality: 99,
        LastName:  nil
        DOB: client_dob,
        DOBDataQuality: client.dob ? 2 : 99

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
        LastPermanentStreet: nil,
        LastPermanentCity: nil,
        LastPermanentState: nil,
        LastPermanentZIP: nil,
        AddressDataQuality: 99,
        last_locality: nil,
        last_zipcode: nil
      }
    end

    def client_dob(date)
      return nil unless date
      Faker::Date.between(
        from: date - 6.months
        to: date + 6.months
      )
    end
  end
end
