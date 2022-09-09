class AddRequiredMatchPercentMetToBostonProjectScorecard < ActiveRecord::Migration[6.1]
  def change
    add_column :boston_project_scorecard_reports, :required_match_percent_met, :boolean
  end
end
