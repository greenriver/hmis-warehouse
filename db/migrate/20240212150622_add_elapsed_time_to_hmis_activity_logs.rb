class AddElapsedTimeToHmisActivityLogs < ActiveRecord::Migration[6.1]
  def change
    add_column :hmis_activity_logs, :resolved_at, :timestamp
  end
end
