###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Import::HmisTwentyTwenty
  class EnrollmentCoc < GrdaWarehouse::Hud::EnrollmentCoc
    include ::Import::HmisTwentyTwenty::Shared
    include TsqlImport
    self.hud_key = :EnrollmentCoCID
    setup_hud_column_access(GrdaWarehouse::Hud::EnrollmentCoc.hud_csv_headers(version: '2020'))

    def self.date_provided_column
      :InformationDate
    end

    def self.file_name
      'EnrollmentCoC.csv'
    end
  end
end
