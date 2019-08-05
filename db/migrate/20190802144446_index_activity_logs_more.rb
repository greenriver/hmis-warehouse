class IndexActivityLogsMore < ActiveRecord::Migration
  def change
    add_index :activity_logs, [:created_at, :item_model, :user_id]
  end
end
