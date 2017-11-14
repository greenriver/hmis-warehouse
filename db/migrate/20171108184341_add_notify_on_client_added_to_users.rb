class AddNotifyOnClientAddedToUsers < ActiveRecord::Migration
  def change
    add_column :users, :notify_on_client_added, :boolean, default: false
  end
end
