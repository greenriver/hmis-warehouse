###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::Import::HmisTwentyTwenty
  class Client < GrdaWarehouse::Hud::Client
    include ::Import::HmisTwentyTwenty::Shared
    include TsqlImport
    self.hud_key = :PersonalID
    setup_hud_column_access( GrdaWarehouse::Hud::Client.hud_csv_headers(version: '2020') )

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
