class AddMigratedColumnToVispdat < ActiveRecord::Migration[4.2]
  def change
    add_column :vispdats, :migrated, :boolean, null: false, default: false
  end
end
