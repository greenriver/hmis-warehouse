###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Export::HmisTwentyTwenty
  class Inventory < GrdaWarehouse::Import::HmisTwentyTwenty::Inventory
    include ::Export::HmisTwentyTwenty::Shared
    setup_hud_column_access( GrdaWarehouse::Hud::Inventory.hud_csv_headers(version: '2020') )

    self.hud_key = :InventoryID

    belongs_to :project_with_deleted, class_name: 'GrdaWarehouse::Hud::WithDeleted::Project', primary_key: [:ProjectID, :data_source_id], foreign_key: [:ProjectID, :data_source_id], inverse_of: :inventories

    def apply_overrides row, data_source_id:
      row[:CoCCode] = enrollment_coc_from_project_coc(row[:ProjectID], data_source_id) if row[:CoCCode].blank?

      return row
    end

  end
end