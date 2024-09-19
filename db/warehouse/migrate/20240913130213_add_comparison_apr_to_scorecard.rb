class AddComparisonAprToScorecard < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    safety_assured do
      add_reference :boston_project_scorecard_reports, :comparison_apr, null: true
    end
  end
end
