class AddDeletedAtToUserRole < ActiveRecord::Migration[4.2]
  def change
    add_column :user_roles, :deleted_at, :datetime, index: true
  end
end
