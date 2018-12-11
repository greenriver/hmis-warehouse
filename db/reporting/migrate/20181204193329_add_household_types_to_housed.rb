class AddHouseholdTypesToHoused < ActiveRecord::Migration
  def change
    add_column :warehouse_houseds, :presented_as_individual, :boolean, default: false
    add_column :warehouse_houseds, :children_only, :boolean, default: false
    add_column :warehouse_houseds, :individual_adult, :boolean, default: false
  end
end
