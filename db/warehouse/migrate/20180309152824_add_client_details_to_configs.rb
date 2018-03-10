class AddClientDetailsToConfigs < ActiveRecord::Migration
  def change
    add_column :configs, :client_details, :text
  end
end
