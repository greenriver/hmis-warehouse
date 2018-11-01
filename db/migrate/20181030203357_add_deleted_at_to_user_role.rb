class AddDeletedAtToUserRole < ActiveRecord::Migration
  def change
    add_column :user_roles, :deleted_at, :datetime, index: true
  end
end
