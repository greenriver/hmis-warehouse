class AddMigratedColumnToVispdat < ActiveRecord::Migration
  def change
    add_column :vispdats, :migrated, :boolean, null: false, default: false
  end
end
