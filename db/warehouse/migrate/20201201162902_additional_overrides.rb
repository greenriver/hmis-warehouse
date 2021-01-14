class AdditionalOverrides < ActiveRecord::Migration[5.2]
  def change
    add_column :Project, :target_population_override, :integer
    add_column :Project, :tracking_method_override, :integer
    add_column :Project, :operating_end_date_override, :date
    add_column :Inventory, :inventory_end_date_override, :date
  end
end
