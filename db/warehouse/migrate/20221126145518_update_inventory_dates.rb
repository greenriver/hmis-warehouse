class UpdateInventoryDates < ActiveRecord::Migration[6.1]
  def up
    ids = HmisDataQualityTool::Inventory.distinct.pluck(:inventory_id)
    return unless ids.present?

    dates = GrdaWarehouse::Hud::Inventory.
      where(id: ids).
      pluck(:id, :InventoryStartDate, :InventoryEndDate)

    dates.each do |id, start_date, end_date|
      HmisDataQualityTool::Inventory.where(inventory_id: id).
      update_all(
        inventory_start_date: start_date,
        inventory_end_date: end_date,
      )
    end
  end
end
