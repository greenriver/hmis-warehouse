class AddEfficiencyAmountScorecardFields < ActiveRecord::Migration[5.2]
  def change
    change_table :project_scorecard_reports do |t|
      t.integer :budget_plus_match
      t.integer :prior_amount_awarded
      t.integer :prior_funds_expended
    end
  end
end
