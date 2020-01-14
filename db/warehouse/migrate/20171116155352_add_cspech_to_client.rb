class AddCspechToClient < ActiveRecord::Migration[4.2]
  def change
    add_column :Client, :cspech_eligible, :boolean, default: false
  end
end
