class AddBostonScorecardFinancialPerformance < ActiveRecord::Migration[6.1]
  def change
    change_table :boston_project_scorecard_reports do |t|
      t.integer :invoicing
      t.float :application_budget
      t.integer :proposed_households_served
      t.float :proposal_ftes
      t.integer :actual_households_served
      t.float :amount_agency_spent
      t.float :returned_funds
      t.float :average_utilization_rate
    end
  end
end
