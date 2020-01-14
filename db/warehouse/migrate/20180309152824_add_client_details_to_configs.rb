class AddClientDetailsToConfigs < ActiveRecord::Migration[4.2]
  def change
    add_column :configs, :client_details, :text
  end
end
