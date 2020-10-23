class CreateProjectScorecardReport < ActiveRecord::Migration[5.2]
  def change
    create_table :project_scorecard_reports do |t|
      t.references :project
      t.string :status

      t.timestamp :deleted_at
      t.timestamps
    end
  end
end
