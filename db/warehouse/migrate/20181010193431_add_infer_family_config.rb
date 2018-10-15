class AddInferFamilyConfig < ActiveRecord::Migration
  def change
    add_column :configs, :infer_family_from_household_id, :boolean, null: false, default: false
  end
end
