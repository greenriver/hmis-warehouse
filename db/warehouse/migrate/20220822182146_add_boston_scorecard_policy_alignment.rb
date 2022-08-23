class AddBostonScorecardPolicyAlignment < ActiveRecord::Migration[6.1]
  def change
    change_table :boston_project_scorecard_reports do |t|
    t.jsonb :subpopulations_served
    t.boolean :practices_housing_first
    t.jsonb :vulnerable_subpopulations_served
    end
  end
end
