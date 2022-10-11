class AddBostonScorecardProjectQuality < ActiveRecord::Migration[6.1]
  def change
    change_table :boston_project_scorecard_reports do |t|
      t.boolean :initial_goals_pass
      t.string :initial_goals_notes
      t.boolean :timeliness_pass
      t.string :timeliness_notes
      t.boolean :independent_living_pass
      t.string :independent_living_notes
      t.boolean :management_oversight_pass
      t.string :management_oversight_notes
      t.boolean :prioritization_pass
      t.string :prioritization_notes
    end
  end
end
