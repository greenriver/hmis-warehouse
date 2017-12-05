class NotifyUsersOnAnomalyCreation < ActiveRecord::Migration
  def change
    add_column :users, :notify_on_anomaly_identified, :boolean, default: false, null: false
  end
end
