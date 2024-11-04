###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'faker'
module GrdaWarehouse::Tasks::ScrubPii < BaseReplacement
  class FakeReplacement

    def client_attrs(client)
      id = client.id
      {
        FirstName: "FirstName#{id}",
        MiddleName: "MiddleName#{id}",
        LastName: "LastName#{id}"
        NameDataQuality: 2,
      }
    end

    def enrollment_attrs(enrollment)
      {
        LastPermanentStreet: Faker::Address.street_address,
        LastPermanentCity: nil,
        LastPermanentState: nil,
        LastPermanentZIP: nil,
        AddressDataQuality: nil,
        last_locality: nil,
        last_zipcode: nil
      }
    end

  end
end
