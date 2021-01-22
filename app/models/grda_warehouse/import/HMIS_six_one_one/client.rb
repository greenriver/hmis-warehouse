###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Import::HMISSixOneOne
  class Client < GrdaWarehouse::Hud::Client
    include ::Import::HMISSixOneOne::Shared
    include TsqlImport
    self.hud_key = :PersonalID
    setup_hud_column_access( GrdaWarehouse::Hud::Client.hud_csv_headers(version: '6.11') )

    def self.deidentify_client_name row
      row['FirstName'] = "First_#{row['PersonalID']}"
      row['LastName'] = "Last_#{row['PersonalID']}"
      row
    end

    def self.file_name
      'Client.csv'
    end
  end
end
