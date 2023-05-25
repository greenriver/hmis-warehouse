class AddColumnsToBostonScorecard < ActiveRecord::Migration[6.1]
  def change
    add_column :boston_project_scorecard_reports, :increased_employment_income, :float
    add_column :boston_project_scorecard_reports, :increased_other_income, :float
    add_column :boston_project_scorecard_reports, :invoicing_timeliness, :integer
    add_column :boston_project_scorecard_reports, :invoicing_accuracy, :integer
  end
end
