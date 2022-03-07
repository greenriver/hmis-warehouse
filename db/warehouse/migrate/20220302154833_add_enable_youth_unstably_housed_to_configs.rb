class AddEnableYouthUnstablyHousedToConfigs < ActiveRecord::Migration[6.1]
  def change
    add_column :configs, :enable_youth_unstably_housed, :boolean, default: true
  end
end
