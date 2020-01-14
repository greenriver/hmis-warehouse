class AddHousingAuthorityEligibleToClient < ActiveRecord::Migration[4.2]
  def change
    add_column :Client, :ha_eligible, :boolean, default: false, null: false
  end
end
