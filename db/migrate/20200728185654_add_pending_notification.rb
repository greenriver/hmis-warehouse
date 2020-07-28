class AddPendingNotification < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :receive_account_request_notifications, :boolean, default: false
  end
end
