###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvImporter::GrdaWarehouse::Hud
  module InventoryExtension
    extend ActiveSupport::Concern

    included do
      has_many :imported_items_2022, class_name: '::HmisCsvTwentyTwentyTwo::Importer::Inventory', primary_key: [:InventoryID, :data_source_id], foreign_key: [:InventoryID, :data_source_id]
      has_many :loaded_items_2022, class_name: '::HmisCsvTwentyTwentyTwo::Loader::Inventory', primary_key: [:InventoryID, :data_source_id], foreign_key: [:InventoryID, :data_source_id]
    end
  end
end
