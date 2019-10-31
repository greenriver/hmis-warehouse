class AddStaticColumnCountToCohorts < ActiveRecord::Migration[4.2]
  def change
    add_column :cohorts, :static_column_count, :integer, null: false, default: 3
  end
end
