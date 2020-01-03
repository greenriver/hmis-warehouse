###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::Import::HmisTwentyTwenty
  class EmploymentEducation < GrdaWarehouse::Hud::EmploymentEducation
    include ::Import::HmisTwentyTwenty::Shared
    include TsqlImport
    self.hud_key = :EmploymentEducationID
    setup_hud_column_access( GrdaWarehouse::Hud::EmploymentEducation.hud_csv_headers(version: '2020') )

    def self.date_provided_column
      :InformationDate
    end

    def self.file_name
      'EmploymentEducation.csv'
    end

  end
end