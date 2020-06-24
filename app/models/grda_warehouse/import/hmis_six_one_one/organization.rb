###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Import::HMISSixOneOne
  class Organization < GrdaWarehouse::Hud::Organization
    include ::Import::HMISSixOneOne::Shared
    include TsqlImport
    self.hud_key = :OrganizationID
    setup_hud_column_access( GrdaWarehouse::Hud::Organization.hud_csv_headers(version: '6.11') )

    def self.file_name
      'Organization.csv'
    end

  end
end