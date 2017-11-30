class AddCspechToClient < ActiveRecord::Migration
  def change
    add_column :Client, :cspech_eligible, :boolean, default: false
  end
end
