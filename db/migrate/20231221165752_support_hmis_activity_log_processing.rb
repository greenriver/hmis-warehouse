class SupportHmisActivityLogProcessing < ActiveRecord::Migration[6.1]
  def change
    add_column :hmis_activity_logs, :processed_at, :date
    create_table :hmis_activity_logs_clients, id: false do |t|
      t.references :activity_log, null: false
      t.references :client, null: false
    end

    create_table :hmis_activity_logs_enrollments, id: false do |t|
      t.references :activity_log, null: false
      t.references :enrollment, null: false
      t.references :project, null: true
    end
  end
end
