class AddUnitLevelAttributesToClients < ActiveRecord::Migration
  def change
    add_column :Client, :requires_ground_floor, :boolean, default: false
    add_column :Client, :requires_wheelchair_accessibility, :boolean, default: false
    add_column :Client, :required_number_of_bedrooms, :integer, default: 1
    add_column :Client, :required_minimum_occupancy, :integer, default: 1
  end
end
