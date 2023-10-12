class AddSystemToUserGroup < ActiveRecord::Migration[6.1]
  def change
    add_column :user_groups, :system, :boolean, default: false, null: false
  end
end
