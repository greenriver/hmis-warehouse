class AddComparisonCountsToResults < ActiveRecord::Migration[5.2]
  def change
    add_column :pm_results, :comparison_primary_value, :integer
  end
end
