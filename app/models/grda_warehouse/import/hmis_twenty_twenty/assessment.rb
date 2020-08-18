###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
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

    def self.fix_row(row)
      # Enforce a date (HMISs keep sending them without dates)
      row['AssessmentDate'] = row['AssessmentDate'].presence || row['CreatedDate']
      row['AssessmentLocation'] = row['AssessmentLocation'].presence || 'Unknown'
      row['AssessmentType'] = row['AssessmentType'].presence || 'Unknown'
      row['AssessmentLevel'] = row['AssessmentLevel'].presence || 'Unknown'
      row['PrioritizationStatus'] = row['PrioritizationStatus'].presence || 'Unknown'

      row
    end

  end
end