###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HmisCsvTwentyTwenty::Importer
  class CurrentLivingSituation < GrdaWarehouse::Hud::Base
    include ImportConcern
    include ::HMIS::Structure::CurrentLivingSituation
    # Because GrdaWarehouse::Hud::* defines the table name, we can't use table_name_prefix :(
    self.table_name = 'hmis_2020_current_living_situations'

    def self.hmis_validations
      {
        CurrentLivingSituation: [
          class: HmisCsvValidation::NonBlank,
        ],
      }
    end
  end
end
