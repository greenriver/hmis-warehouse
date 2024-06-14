###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwentyFour::Loader
  class Exit < GrdaWarehouse::Hud::Base
    include LoaderConcern
    include ::HmisStructure::Exit
    # Because GrdaWarehouse::Hud::* defines the table name, we can't use table_name_prefix :(
    self.table_name = 'hmis_csv_2024_exits'
    self.primary_key = 'id'
  end
end
