class IndexActivityLogsMoreAgain < ActiveRecord::Migration[4.2]
  def change
    add_index :activity_logs, [ :user_id, :item_model, :created_at ]
    add_index :activity_logs, [ :item_model, :user_id, :created_at ]
  end
end
