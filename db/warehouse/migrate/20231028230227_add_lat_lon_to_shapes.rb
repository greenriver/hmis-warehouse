class AddLatLonToShapes < ActiveRecord::Migration[6.1]
  def change
    add_column :places, :lat, :float
    add_column :places, :lon, :float

    StrongMigrations.disable_check(:add_index)
    add_index :places, [:lat, :lon]
  ensure
    StrongMigrations.enable_check(:add_index)
  end
end
