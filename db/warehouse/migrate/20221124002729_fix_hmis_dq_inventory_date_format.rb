class FixHmisDqInventoryDateFormat < ActiveRecord::Migration[6.1]
  def up
    remove_column(:hmis_dqt_inventories, :inventory_start_date, :integer)
    remove_column(:hmis_dqt_inventories, :inventory_end_date, :integer)
    add_column(:hmis_dqt_inventories, :inventory_start_date, :date)
    add_column(:hmis_dqt_inventories, :inventory_end_date, :date)
  end
end
