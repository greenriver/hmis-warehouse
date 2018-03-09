class AddDetailsToClients < ActiveRecord::Migration
  def change
    add_column :Client, :congregate_housing, :boolean, default: false
    add_column :Client, :sober_housing, :boolean, default: false
  end
end
