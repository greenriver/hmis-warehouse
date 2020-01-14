class AddVashEligibleToClient < ActiveRecord::Migration[4.2]
  def change
    add_column :Client, :vash_eligible, :boolean, default: false
  end
end
