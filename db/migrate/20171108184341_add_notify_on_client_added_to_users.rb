class AddNotifyOnClientAddedToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :notify_on_client_added, :boolean, default: false
  end
end
