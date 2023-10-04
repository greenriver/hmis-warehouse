class AddEmailIndexToHudUser < ActiveRecord::Migration[6.1]
  def change
    StrongMigrations.disable_check(:add_index)
    add_index :User, [:data_source_id, :UserEmail], unique: false, name: :ds_email_idx
  ensure
    StrongMigrations.enable_check(:add_index)
  end
end
