class AddStaffToEpicThrives < ActiveRecord::Migration[6.1]
  def change
    add_column :epic_thrives, :staff, :string
  end
end
