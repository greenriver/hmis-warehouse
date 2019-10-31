class AddDetailsToClients < ActiveRecord::Migration[4.2]
  def change
    add_column :Client, :congregate_housing, :boolean, default: false
    add_column :Client, :sober_housing, :boolean, default: false
  end
end
