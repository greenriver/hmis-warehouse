class AddArchiveToBostonScorecard < ActiveRecord::Migration[6.1]
  def change
    change_table :boston_project_scorecard_reports do |t|
      t.string :archive
    end
  end
end
