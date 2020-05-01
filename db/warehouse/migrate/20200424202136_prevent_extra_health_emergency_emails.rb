class PreventExtraHealthEmergencyEmails < ActiveRecord::Migration[5.2]
  def up
    GrdaWarehouse::HealthEmergency::AmaRestriction.update_all(notification_batch_id: 0, notification_at: Time.current)
    GrdaWarehouse::HealthEmergency::Test.update_all(notification_batch_id: 0, notification_at: Time.current)
  end
end
