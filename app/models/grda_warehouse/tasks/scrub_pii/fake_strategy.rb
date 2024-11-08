###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'faker'
module GrdaWarehouse::Tasks::ScrubPii
  class FakeStrategy < BaseStrategy
    def client_attrs(client)
      super(client).merge(
        {
          SSN: Faker::IdNumber.invalid,
          FirstName: Faker::Name.first_name,
          MiddleName: Faker::Name.middle_name,
          LastName: Faker::Name.last_name,
          NameDataQuality: 99,
          SSNDataQuality: 99,
          DOBDataQuality: client.dob ? 2 : 99,
        },
      )
    end

    def enrollment_attrs(enrollment)
      super(enrollment).merge(
        {
          LastPermanentStreet: Faker::Address.street_address,
          LastPermanentCity: Faker::Address.city,
          LastPermanentState: Faker::Address.state_abbr,
          LastPermanentZIP: Faker::Address.zip,
          last_locality: nil,
          last_zipcode: nil,
        },
      )
    end
  end

  def scrub_ssn_cdes(scope)
    scope.each do |cde|
      cde.value = Faker::IdNumber.invalid
      cde.save!
    end
  end

  def scrub_dob_cdes(scope)
    scope.each do |cde|
      cde.value = scramble_dob(cde.value)
      cde.save!
    end
  end
end
