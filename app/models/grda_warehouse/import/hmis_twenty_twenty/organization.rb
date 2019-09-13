###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::Import::HmisTwentyTwenty
  class Organization < GrdaWarehouse::Hud::Organization
    include ::Import::HmisTwentyTwenty::Shared
    include TsqlImport
    self.hud_key = :OrganizationID
    setup_hud_column_access( GrdaWarehouse::Hud::Organization.hud_csv_headers(version: '2020') )

    def self.file_name
      'Organization.csv'
    end

  end
end