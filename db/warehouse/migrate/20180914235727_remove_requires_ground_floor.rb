class RemoveRequiresGroundFloor < ActiveRecord::Migration
  def change
    remove_column :Client, :requires_ground_floor, :boolean, default: false
  end
end
