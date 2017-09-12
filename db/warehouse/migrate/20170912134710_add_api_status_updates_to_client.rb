class AddApiStatusUpdatesToClient < ActiveRecord::Migration
  def change
    add_column :Client, :api_update_in_process, :boolean, null: false, default: false
    add_column :Client, :api_update_started_at, :datetime
    add_column :Client, :api_last_updated_at, :datetime
  end
end
