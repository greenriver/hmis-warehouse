class AddStatusToEquipment < ActiveRecord::Migration
  def change
    add_column :equipment, :status, :string
  end
end
