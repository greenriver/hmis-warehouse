class CreateGenerateServiceHistoryBatchLog < ActiveRecord::Migration
  def change
    add_column :generate_service_history_log, :batches, :integer
    create_table :generate_service_history_batch_logs do |t|
      t.references :generate_service_history_log
      t.integer :to_process
      t.integer :updated
      t.integer :patched
      t.references :delayed_job
      t.timestamps null: false
    end
  end
end
