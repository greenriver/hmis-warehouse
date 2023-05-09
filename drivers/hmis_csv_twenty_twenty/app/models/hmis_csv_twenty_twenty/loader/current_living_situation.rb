###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwenty::Loader
  class CurrentLivingSituation < GrdaWarehouse::Hud::Base
    include LoaderConcern
    include ::HmisStructure::CurrentLivingSituation
    # Because GrdaWarehouse::Hud::* defines the table name, we can't use table_name_prefix :(
    self.table_name = 'hmis_csv_2020_current_living_situations'
  end
end
