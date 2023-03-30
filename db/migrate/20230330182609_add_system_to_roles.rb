class AddSystemToRoles < ActiveRecord::Migration[6.1]
  def change
    add_column :roles, :system, :boolean, default: false, null: false
  end
end
