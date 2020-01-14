class AddHohToHoused < ActiveRecord::Migration[5.2]
  def change
    add_column :warehouse_houseds, :head_of_household, :boolean, default: false
  end
end
