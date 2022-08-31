class AddBostonScorecardDataQuality < ActiveRecord::Migration[6.1]
  def change
    change_table :boston_project_scorecard_reports do |t|
      t.float :pii_error_rate
      t.float :ude_error_rate
      t.float :income_and_housing_error_rate
    end
  end
end
