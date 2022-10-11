class AddBostonScorecardProjectPerformance < ActiveRecord::Migration[6.1]
  def change
    change_table :boston_project_scorecard_reports do |t|
      t.float :rrh_exits_to_ph
      t.float :psh_stayers_or_to_ph
      t.float :increased_stayer_employment_income
      t.float :increased_stayer_other_income
      t.float :increased_leaver_employment_income
      t.float :increased_leaver_other_income
      t.integer :days_to_lease_up
    end
  end
end
