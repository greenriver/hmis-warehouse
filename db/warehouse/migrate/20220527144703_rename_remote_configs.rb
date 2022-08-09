class RenameRemoteConfigs < ActiveRecord::Migration[6.1]
  def change
    rename_table :remote_configs, :remote_credentials
  end
end
