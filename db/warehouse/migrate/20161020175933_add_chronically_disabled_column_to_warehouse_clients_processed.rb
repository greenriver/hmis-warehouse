class AddChronicallyDisabledColumnToWarehouseClientsProcessed < ActiveRecord::Migration
  def up
    add_column table.table_name, :chronically_homeless, :boolean, null: false, default: false
  end

  def down
    remove_column table.table_name, :chronically_homeless
  end

  def table
    GrdaWarehouse::WarehouseClientsProcessed
  end
end
