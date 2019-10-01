class AddVashEligibleToClient < ActiveRecord::Migration
  def change
    add_column :Client, :vash_eligible, :boolean, default: false
  end
end
