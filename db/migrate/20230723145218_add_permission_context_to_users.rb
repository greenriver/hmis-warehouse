class AddPermissionContextToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :permission_context, :string, default: :role_based
  end
end
