###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::Export::HMIS2020
  class Inventory < GrdaWarehouse::Import::HMIS2020::Inventory
    include ::Export::HMIS2020::Shared
    setup_hud_column_access( GrdaWarehouse::Hud::Inventory.hud_csv_headers(version: '2020') )

    self.hud_key = :InventoryID

    belongs_to :project_with_deleted, class_name: 'GrdaWarehouse::Hud::WithDeleted::Project', primary_key: [:ProjectID, :data_source_id], foreign_key: [:ProjectID, :data_source_id], inverse_of: :inventories

    # Sometimes we don't have inventory InformationDate but we do have InventoryStartDate
    def apply_overrides row, data_source_id:
      row[:InformationDate] = row[:InventoryStartDate] if row[:InformationDate].blank?
      return row
    end

  end
end