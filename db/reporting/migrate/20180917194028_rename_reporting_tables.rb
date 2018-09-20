class RenameReportingTables < ActiveRecord::Migration
  def change
    remove_column :houseds, :first_name, :string
    remove_column :houseds, :last_name, :string
    remove_column :houseds, :ssn, :string
    rename_table :houseds, :warehouse_houseds
    rename_table :returns, :warehouse_returns
  end
end
