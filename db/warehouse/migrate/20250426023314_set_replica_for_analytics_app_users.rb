class SetReplicaForAnalyticsAppUsers < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      execute('ALTER TABLE analytics.app_users REPLICA IDENTITY FULL')
    end
  end
end
