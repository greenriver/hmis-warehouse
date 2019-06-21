###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::Import::HMISFiveOne
  class Site < GrdaWarehouse::Hud::Site
    include ::Import::HMISFiveOne::Shared
    include TsqlImport

    setup_hud_column_access( GrdaWarehouse::Hud::Site.hud_csv_headers(version: '5.1') )

    self.hud_key = :SiteID

    def self.file_name
      'Site.csv'
    end
  end
end