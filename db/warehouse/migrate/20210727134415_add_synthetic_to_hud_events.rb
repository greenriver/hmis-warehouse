class AddSyntheticToHudEvents < ActiveRecord::Migration[5.2]
  def change
    add_column :Event, :synthetic, :boolean, default: false
  end
end
