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
          SSN: invalid_ssn,
          FirstName: Faker::Name.first_name,
          MiddleName: Faker::Name.middle_name,
          LastName: Faker::Name.last_name,
          NameDataQuality: 1,
          SSNDataQuality: 1,
        },
      )
    end

    def invalid_ssn
      # use 999 to make it more obvious the ssn is invalid
      Faker::IdNumber.invalid.gsub(/^\d{3}/, '999')
    end
  end
end
