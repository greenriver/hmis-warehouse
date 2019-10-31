class AddNotifyOnVispdatCompletedToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :notify_on_vispdat_completed, :boolean, default: false
  end
end
