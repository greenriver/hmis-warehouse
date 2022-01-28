class AddDenominatorsAndNumerators < ActiveRecord::Migration[5.2]
  def change
    add_column :pm_results, :reporting_numerator, :integer
    add_column :pm_results, :reporting_denominator, :integer
    add_column :pm_results, :comparison_numerator, :integer
    add_column :pm_results, :comparison_denominator, :integer
  end
end
