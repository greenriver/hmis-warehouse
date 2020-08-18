###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Import::HmisTwentyTwenty
  class AssessmentQuestion < GrdaWarehouse::Hud::AssessmentQuestion
    include ::Import::HmisTwentyTwenty::Shared
    include TsqlImport
    self.hud_key = :AssessmentQuestionID
    setup_hud_column_access( GrdaWarehouse::Hud::AssessmentQuestion.hud_csv_headers(version: '2020') )

    def self.file_name
      'AssessmentQuestions.csv'
    end

  end
end