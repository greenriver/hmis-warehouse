###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwentyTwo::Loader
  class HealthAndDv < GrdaWarehouse::Hud::Base
    include LoaderConcern
    include ::HmisStructure::HealthAndDv
    # Because GrdaWarehouse::Hud::* defines the table name, we can't use table_name_prefix :(
    self.table_name = 'hmis_csv_2022_health_and_dvs'
    self.primary_key = 'id'
  end
end
