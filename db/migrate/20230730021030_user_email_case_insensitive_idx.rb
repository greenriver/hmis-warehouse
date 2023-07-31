class UserEmailCaseInsensitiveIdx < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!
  # Protect against non-unique account emails
  def change
    # note, this is redundant with existing email index. However devise's
    # default query needs the existing index for performance.
    add_index :users, 'TRIM(LOWER(email))', unique: true, name: 'index_active_users_on_lower_email', where: 'deleted_at IS NULL', algorithm: :concurrently
  end
end
