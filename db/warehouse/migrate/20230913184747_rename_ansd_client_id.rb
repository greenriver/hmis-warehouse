class RenameAnsdClientId < ActiveRecord::Migration[6.1]
  def change
    StrongMigrations.disable_check(:rename_column)

    rename_column :ansd_events, :client_id, :personal_id
    rename_column :ansd_enrollments, :client_id, :personal_id
  ensure
    StrongMigrations.enable_check(:rename_column)
  end
end
