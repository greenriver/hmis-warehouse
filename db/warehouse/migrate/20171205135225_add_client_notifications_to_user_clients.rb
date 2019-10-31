class AddClientNotificationsToUserClients < ActiveRecord::Migration[4.2]
  def change
    add_column :user_clients, :client_notifications, :boolean, default: false
  end
end
