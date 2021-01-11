class AddSyncDuration < ActiveRecord::Migration[5.2]
  def change
    add_column :configs, :cas_sync_months, :integer, default: 3
  end
end
