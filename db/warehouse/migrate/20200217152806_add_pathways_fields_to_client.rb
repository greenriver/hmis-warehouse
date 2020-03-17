class AddPathwaysFieldsToClient < ActiveRecord::Migration[5.2]
  def change
    add_column :Client, :income_maximization_assistance_requested, :boolean, default: false, null: false
    add_column :Client, :income_total_monthly, :integer
    add_column :Client, :pending_subsidized_housing_placement, :boolean, default: false, null: false
    add_column :Client, :pathways_domestic_violence, :boolean, default: false, null: false
    add_column :Client, :rrh_th_desired, :boolean, default: false, null: false
    add_column :Client, :sro_ok, :boolean, default: false, null: false
    add_column :Client, :pathways_other_accessibility, :boolean, default: false, null: false
    add_column :Client, :pathways_disabled_housing, :boolean, default: false, null: false
    add_column :Client, :evicted, :boolean, default: false, null: false
  end
end
