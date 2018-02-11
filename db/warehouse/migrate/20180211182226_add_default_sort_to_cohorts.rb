class AddDefaultSortToCohorts < ActiveRecord::Migration
  def change
    add_column :cohorts, :default_sort_direction, :string, default: :desc
  end
end
