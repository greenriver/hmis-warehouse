class IndexActivityLogs < ActiveRecord::Migration
  def change
    add_index :activity_logs, [:item_model, :user_id]
  end
end
