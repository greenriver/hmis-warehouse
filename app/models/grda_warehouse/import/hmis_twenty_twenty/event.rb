###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::Import::HmisTwentyTwenty
  class Event < GrdaWarehouse::Hud::Event
    include ::Import::HmisTwentyTwenty::Shared
    include TsqlImport
    self.hud_key = :EventID
    setup_hud_column_access( GrdaWarehouse::Hud::Event.hud_csv_headers(version: '2020') )

    def self.date_provided_column
      :EventDate
    end

    def self.file_name
      'Event.csv'
    end

  end
end