class CreateDashboardExportReports < ActiveRecord::Migration
  def change
    create_table :dashboard_export_reports do |t|
      t.references :file
      t.references :user
      t.references :job
      t.string :coc_code
      t.timestamps null: false
      t.datetime :started_at
      t.datetime :completed_at
    end
  end
end
