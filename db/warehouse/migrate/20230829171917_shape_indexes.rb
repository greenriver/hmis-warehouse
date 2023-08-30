class ShapeIndexes < ActiveRecord::Migration[6.1]
  def change
    StrongMigrations.disable_check(:add_index)
    add_index :shape_states, :statefp
  ensure
    StrongMigrations.enable_check(:add_index)
  end
end
