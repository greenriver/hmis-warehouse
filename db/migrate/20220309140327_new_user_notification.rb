class NewUserNotification < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :notify_on_new_account, :boolean, default: false, null: false
  end
end
