class RemoveChronicFieldsFromServiceHistoryProcessed < ActiveRecord::Migration
  def change
    table_name = GrdaWarehouse::WarehouseClientsProcessed.table_name
    remove_column table_name, :individual_days_homeless_last_three_years, :integer, default: 0, null: false
    remove_column table_name, :individual_months_homeless_last_three_years, :integer, default: 0, null: false
    remove_column table_name, :individual_chronically_homeless, :boolean, default: false, null: false
    remove_column table_name, :days_homeless_last_three_years, :integer    
    remove_column table_name, :months_homeless_last_three_years, :integer
  end
end
