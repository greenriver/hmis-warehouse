###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HmisCsvImporter::TwentyTwenty
  class Inventory < GrdaWarehouse::Hud::Inventory
    include ImportConcern
    # Because GrdaWarehouse::Hud::* defines the table name, we can't use table_name_prefix :(
    self.table_name = 'hmis_csv_importer_twenty_twenty_inventories'
  end
end
