class AddDefaultSortToCohorts < ActiveRecord::Migration[4.2]
  def change
    add_column :cohorts, :default_sort_direction, :string, default: :desc
  end
end
