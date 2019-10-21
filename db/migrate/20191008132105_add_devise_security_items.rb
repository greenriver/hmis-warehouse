class AddDeviseSecurityItems < ActiveRecord::Migration
  def change
    add_column :users, :unique_session_id, :string
    add_column :users, :last_activity_at, :datetime, index: true
    add_column :users, :expired_at, :datetime, index: true
  end
end
