class CreateProjectReportingTables < ActiveRecord::Migration
  def change
    create_table :project_contacts do |t|
      t.references :project, index: true, null: false
      t.string :email, null: false
      t.string :first_name
      t.string :last_name
      t.datetime :deleted_at
      t.timestamps

    end

    create_table :project_data_quality do |t|
      t.references :project, index: true, null: false
      t.references :project_contact
      t.string :type
      t.date :start
      t.date :end
      t.json :report
      t.datetime :sent_at
      t.datetime :started_at
      t.datetime :completed_at
      t.datetime :deleted_at
      t.timestamps

    end
  end
end
