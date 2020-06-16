###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HmisCsvTwentyTwenty::Importer
  class HealthAndDv < GrdaWarehouse::Hud::Base
    include ImportConcern
    include ::HMIS::Structure::HealthAndDv
    # Because GrdaWarehouse::Hud::* defines the table name, we can't use table_name_prefix :(
    self.table_name = 'hmis_2020_health_and_dvs'
  end
end
