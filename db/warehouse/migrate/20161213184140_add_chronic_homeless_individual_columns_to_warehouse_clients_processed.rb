class AddChronicHomelessIndividualColumnsToWarehouseClientsProcessed < ActiveRecord::Migration
  def change
    table_name = GrdaWarehouse::WarehouseClientsProcessed.table_name
    add_column table_name, :individual_days_homeless_last_three_years, :integer, default: 0, null: false
    add_column table_name, :individual_months_homeless_last_three_years, :integer, default: 0, null: false
    add_column table_name, :individual_chronically_homeless, :boolean, default: false, null: false
  end
end
