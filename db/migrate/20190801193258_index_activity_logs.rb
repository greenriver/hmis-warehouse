class IndexActivityLogs < ActiveRecord::Migration[4.2]
  def change
    add_index :activity_logs, [:item_model, :user_id]
  end
end
