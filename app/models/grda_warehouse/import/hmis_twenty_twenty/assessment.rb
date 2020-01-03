###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::Import::HmisTwentyTwenty
  class Assessment < GrdaWarehouse::Hud::Assessment
    include ::Import::HmisTwentyTwenty::Shared
    include TsqlImport
    self.hud_key = :AssessmentID
    setup_hud_column_access( GrdaWarehouse::Hud::Assessment.hud_csv_headers(version: '2020') )

    def self.date_provided_column
      :AssessmentDate
    end

    def self.file_name
      'Assessment.csv'
    end

  end
end