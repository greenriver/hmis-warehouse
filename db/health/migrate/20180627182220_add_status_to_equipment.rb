class AddStatusToEquipment < ActiveRecord::Migration[4.2]
  def change
    add_column :equipment, :status, :string
  end
end
