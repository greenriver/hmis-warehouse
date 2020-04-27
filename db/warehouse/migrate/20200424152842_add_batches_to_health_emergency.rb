class AddBatchesToHealthEmergency < ActiveRecord::Migration[5.2]
  def change
    add_column :health_emergency_tests, :notification_at, :datetime
    add_column :health_emergency_tests, :notification_batch_id, :integer

    add_column :health_emergency_ama_restrictions, :notification_at, :datetime
    add_column :health_emergency_ama_restrictions, :notification_batch_id, :integer
  end
end
