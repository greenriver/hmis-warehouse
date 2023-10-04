class AddEmailIndexToHudUser < ActiveRecord::Migration[6.1]
  def change
    StrongMigrations.disable_check(:add_index)
    add_index :User, [:UserEmail, :data_source_id], unique: false, name: :users_ds_email_idx
  ensure
    StrongMigrations.enable_check(:add_index)
  end
end
