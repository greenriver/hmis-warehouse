class OverrideForProjectCoCZip < ActiveRecord::Migration[5.2]
  def change
    add_column :ProjectCoC, :zip_override, :string
  end
end
