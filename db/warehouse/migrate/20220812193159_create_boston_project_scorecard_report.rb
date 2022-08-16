class CreateBostonProjectScorecardReport < ActiveRecord::Migration[6.1]
  def change
    create_table :boston_project_scorecard_reports do |t|
      t.references :project
      t.references :project_group
      t.string :status, default: 'pending'
      t.references :user

      t.date :start_date, null: false
      t.date :end_date, null: false
      t.references :apr

      t.timestamp :started_at
      t.timestamp :completed_at
      t.timestamp :sent_at
      t.timestamp :deleted_at
      t.timestamps
    end
  end
end
