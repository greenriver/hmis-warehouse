class AddStaticColumnCountToCohorts < ActiveRecord::Migration
  def change
    add_column :cohorts, :static_column_count, :integer, null: false, default: 3
  end
end
