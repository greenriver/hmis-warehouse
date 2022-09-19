class BostonScorecardUpdates < ActiveRecord::Migration[6.1]
  def change
    change_table :boston_project_scorecard_reports do |t|
      t.remove :application_budget
      t.remove :proposal_ftes
      t.remove :proposed_households_served

      t.float :contracted_budget
    end
  end
end
