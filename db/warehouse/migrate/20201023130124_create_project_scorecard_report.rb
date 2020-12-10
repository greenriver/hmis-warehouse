class CreateProjectScorecardReport < ActiveRecord::Migration[5.2]
  def change
    create_table :project_scorecard_reports do |t|
      t.references :project
      t.references :project_group
      t.string :status, default: 'pending'
      t.references :user

      t.timestamp :started_at
      t.timestamp :completed_at
      t.timestamp :sent_at
      t.timestamp :deleted_at
      t.timestamps
    end
  end
end
