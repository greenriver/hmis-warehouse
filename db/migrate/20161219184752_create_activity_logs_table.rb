class CreateActivityLogsTable < ActiveRecord::Migration
  def change
    create_table :activity_logs, :force => true do |t|
      t.string :item_model, index: true
      t.integer :item_id
      t.string :title
      t.integer :user_id, null: false, index: true
      t.string :controller_name, null: false, index: true
      t.string :action_name, null: false
      t.string :method
      t.string :path
      t.string :ip_address, null: false
      t.string :session_hash
      t.text :referrer
      t.text :params
      t.timestamps
    end
  end
end
