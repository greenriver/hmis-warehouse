###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::Import::HMISFiveOne
  class EmploymentEducation < GrdaWarehouse::Hud::EmploymentEducation
    include ::Import::HMISFiveOne::Shared
    include TsqlImport

    setup_hud_column_access( GrdaWarehouse::Hud::EmploymentEducation.hud_csv_headers(version: '5.1') )

    self.hud_key = :EmploymentEducationID

    def self.date_provided_column
      :InformationDate
    end

    def self.file_name
      'EmploymentEducation.csv'
    end

  end
end