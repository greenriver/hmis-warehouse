class AddComparisonAprToScorecard < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_reference :boston_project_scorecard_reports, :comparison_apr, null: true, index: {algorithm: :concurrently}
  end
end
