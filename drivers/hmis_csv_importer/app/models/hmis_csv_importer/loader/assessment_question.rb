###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvImporter::Loader
  class AssessmentQuestion < GrdaWarehouse::Hud::Base
    include LoaderConcern
    include ::HMIS::Structure::AssessmentQuestion
    # Because GrdaWarehouse::Hud::* defines the table name, we can't use table_name_prefix :(
    self.table_name = 'hmis_csv_2022_assessment_questions'
  end
end
