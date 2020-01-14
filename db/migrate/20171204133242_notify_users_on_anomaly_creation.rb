class NotifyUsersOnAnomalyCreation < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :notify_on_anomaly_identified, :boolean, default: false, null: false
  end
end
