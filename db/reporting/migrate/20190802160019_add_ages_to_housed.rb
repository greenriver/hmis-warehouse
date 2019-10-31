class AddAgesToHoused < ActiveRecord::Migration[4.2]
  def change
    add_column :warehouse_houseds, :age_at_search_start, :integer
    add_column :warehouse_houseds, :age_at_search_end, :integer
    add_column :warehouse_houseds, :age_at_housed_date, :integer
    add_column :warehouse_houseds, :age_at_housing_exit, :integer
  end
end
