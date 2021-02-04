###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Import::HMISSixOneOne
  class HealthAndDv < GrdaWarehouse::Hud::HealthAndDv
    include ::Import::HMISSixOneOne::Shared
    include TsqlImport
    self.hud_key = :HealthAndDVID
    setup_hud_column_access(GrdaWarehouse::Hud::HealthAndDv.hud_csv_headers(version: '6.11'))

    def self.date_provided_column
      :InformationDate
    end

    def self.file_name
      'HealthAndDV.csv'
    end
  end
end
