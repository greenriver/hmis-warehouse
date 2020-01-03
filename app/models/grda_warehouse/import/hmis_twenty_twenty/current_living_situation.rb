###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::Import::HmisTwentyTwenty
  class CurrentLivingSituation < GrdaWarehouse::Hud::CurrentLivingSituation
    include ::Import::HmisTwentyTwenty::Shared
    include TsqlImport
    self.hud_key = :CurrentLivingSitID
    setup_hud_column_access( GrdaWarehouse::Hud::CurrentLivingSituation.hud_csv_headers(version: '2020') )

    def self.date_provided_column
      :InformationDate
    end

    def self.file_name
      'CurrentLivingSituation.csv'
    end

  end
end