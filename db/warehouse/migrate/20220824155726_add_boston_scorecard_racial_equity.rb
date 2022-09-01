class AddBostonScorecardRacialEquity < ActiveRecord::Migration[6.1]
  def change
    change_table :boston_project_scorecard_reports do |t|
      t.boolean :barrier_id_process
      t.boolean :plan_to_address_barriers
    end
  end
end
