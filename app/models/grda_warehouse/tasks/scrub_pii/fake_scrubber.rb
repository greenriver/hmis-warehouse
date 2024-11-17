###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'faker'

module GrdaWarehouse::Tasks::ScrubPii
  class FakeScrubber
    def perform(fields)
      fields.each do |field|
        case field.type
        when :ssn
          field.scrub(invalid_ssn)
        when :first_name
          field.scrub(Faker::Name.first_name)
        when :last_name
          field.scrub(Faker::Name.last_name)
        when :middle_name
          field.scrub(Faker::Name.middle_name)
        end
      end
    end

    def invalid_ssn
      # use 999 to make it more obvious the ssn is invalid
      Faker::IdNumber.invalid.gsub(/^\d{3}/, '999')
    end
  end
end
