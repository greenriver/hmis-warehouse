class AddNotifyOnVispdatCompletedToUsers < ActiveRecord::Migration
  def change
    add_column :users, :notify_on_vispdat_completed, :boolean, default: false
  end
end
