###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwentyFour::Loader
  class AssessmentResult < GrdaWarehouse::Hud::Base
    include ::HmisStructure::AssessmentResult
    include LoaderConcern
    # Because GrdaWarehouse::Hud::* defines the table name, we can't use table_name_prefix :(
    self.table_name = 'hmis_csv_2024_assessment_results'
    self.primary_key = 'id'
  end
end
