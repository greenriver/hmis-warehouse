class AddClientNotificationsToUserClients < ActiveRecord::Migration
  def change
    add_column :user_clients, :client_notifications, :boolean, default: false
  end
end
