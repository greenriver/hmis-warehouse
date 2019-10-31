class RemoveRequiresGroundFloor < ActiveRecord::Migration[4.2]
  def change
    remove_column :Client, :requires_ground_floor, :boolean, default: false
  end
end
