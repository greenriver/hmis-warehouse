class AddNoConcernScoreToBostonProjectScorecard < ActiveRecord::Migration[6.1]
  def change
    add_column :boston_project_scorecard_reports, :no_concern, :integer
  end
end
