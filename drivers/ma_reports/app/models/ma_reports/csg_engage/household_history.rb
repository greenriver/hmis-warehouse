###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module MaReports::CsgEngage
  class HouseholdHistory < GrdaWarehouseBase
    self.table_name = :csg_engage_household_histories
    belongs_to :last_program_report, class_name: 'MaReports::CsgEngage::ProgramReport'

    before_save do
      self.fingerprint = self.class.fingerprint_for_household_data(data)
    end

    def self.last_fingerprint_for_household(household_id)
      find_by(household_id: household_id)&.fingerprint
    end

    def self.fingerprint_for_household_data(data)
      Digest::SHA256.hexdigest(data.to_json)
    end
  end
end
