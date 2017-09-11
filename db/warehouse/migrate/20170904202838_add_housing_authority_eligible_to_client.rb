class AddHousingAuthorityEligibleToClient < ActiveRecord::Migration
  def change
    add_column :Client, :ha_eligible, :boolean, default: false, null: false
  end
end
