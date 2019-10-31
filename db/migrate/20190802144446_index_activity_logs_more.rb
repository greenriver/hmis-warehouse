class IndexActivityLogsMore < ActiveRecord::Migration[4.2]
  def change
    add_index :activity_logs, [:created_at, :item_model, :user_id]
  end
end
