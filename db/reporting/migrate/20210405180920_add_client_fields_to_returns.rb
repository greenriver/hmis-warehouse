class AddClientFieldsToReturns < ActiveRecord::Migration[5.2]
  def change
    add_column :warehouse_returns, :gender, :integer
    add_column :warehouse_returns, :race, :string
    add_column :warehouse_returns, :ethnicity, :string
    add_column :warehouse_returns, :hmis_project_id, :string
    add_column :warehouse_houseds, :hmis_project_id, :string
  end
end
