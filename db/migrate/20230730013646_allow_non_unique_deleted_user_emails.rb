class AllowNonUniqueDeletedUserEmails < ActiveRecord::Migration[6.1]
  # allow non-unique emails for deleted users
  def change
    # assuming users table isn't huge, building this index should be quick so
    # it's probably okay to lock the table
    StrongMigrations.disable_check(:add_index)
    add_index :users, :email, unique: true, name: 'index_active_users_on_email', where: 'deleted_at IS NULL'
    remove_index :users, :email, unique: true, name: 'index_users_on_email'
  ensure
    StrongMigrations.enable_check(:add_index)
  end
end
