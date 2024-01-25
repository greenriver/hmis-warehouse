class AddEquityAnalysisFeatureFlag < ActiveRecord::Migration[6.1]
  def change
    add_column :performance_measurement_goals, :equity_analysis_visible, :boolean, default: false, null: false
  end
end
