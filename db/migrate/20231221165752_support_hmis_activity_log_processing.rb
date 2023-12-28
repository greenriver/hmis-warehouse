class SupportHmisActivityLogProcessing < ActiveRecord::Migration[6.1]
  def change
    add_column :hmis_activity_logs, :processed_at, :date
    [
      [:hmis_activity_logs_clients, :client],
      [:hmis_activity_logs_enrollments, :enrollment],
    ].each do |join_table_name, reference|
      create_table join_table_name, id: false do |t|
        t.references :activity_log, null: false
        t.references reference, null: false
      end
    end
  end
end
