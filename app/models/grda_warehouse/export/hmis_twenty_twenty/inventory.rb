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
      # Apply direct overrides
      override = coc_code_override_for(inventory_id: row[:InventoryID].to_i, data_source_id: data_source_id)
      row[:CoCCode] = override if override
      # Apply default value from project coc if not set
      row[:CoCCode] = enrollment_coc_from_project_coc(row[:ProjectID], data_source_id) if row[:CoCCode].blank?

      override = inventory_start_date_override_for(inventory_id: row[:InventoryID].to_i, data_source_id: data_source_id)
      row[:InventoryStartDate] = override if override

      return row
    end

    def coc_code_override_for(inventory_id:, data_source_id:)
      @coc_code_overrides ||= self.class.where.not(coc_code_override: nil).
        pluck(:data_source_id, :id, :coc_code_override).
        map do |ds_id, i_id, coc_code_override|
          if coc_code_override.present?
            [[ds_id, i_id], coc_code_override]
          else
            nil
          end
        end.compact.to_h
      @coc_code_overrides[[data_source_id, inventory_id]]
    end

    def inventory_start_date_override_for(inventory_id:, data_source_id:)
      @inventory_start_date_overrides ||= self.class.where.not(inventory_start_date_override: nil).
        pluck(:data_source_id, :id, :inventory_start_date_override).
        map do |ds_id, i_id, inventory_start_date_override|
          if inventory_start_date_override.present?
            [[ds_id, i_id], inventory_start_date_override]
          else
            nil
          end
        end.compact.to_h
      @inventory_start_date_overrides[[data_source_id, inventory_id]]
    end
  end
end