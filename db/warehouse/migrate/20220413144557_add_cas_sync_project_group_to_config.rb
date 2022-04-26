class AddCasSyncProjectGroupToConfig < ActiveRecord::Migration[6.1]
  def change
    add_column :configs, :cas_sync_project_group_id, :integer, null: true
  end
end
