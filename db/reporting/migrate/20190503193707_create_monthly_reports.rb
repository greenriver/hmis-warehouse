class CreateMonthlyReports < ActiveRecord::Migration
  def change
    create_table :warehouse_monthly_reports do |t|
      t.integer :month, null: false, index: true
      t.integer :year, null: false, index: true, index: true
      t.string :type, index: true
      t.integer :client_id, null: false
      t.integer :head_of_household, null: false, default: 0, index: true
      t.string :household_id, index: true
      t.integer :project_id, null: false, index: true
      t.integer :organization_id, null: false, index: true
      t.integer :destination_id
      t.boolean :first_enrollment, null: false, default: false
      t.boolean :enrolled, null: false, default: false, index: true
      t.boolean :active, null: false, default: false, index: true, index: true
      t.boolean :entered, null: false, default: false, index: true
      t.boolean :exited, null: false, default: false, index: true
      t.integer :project_type, null: false
      t.date :entry_date
      t.date :exit_date
      t.integer :days_since_last_exit
      t.integer :prior_exit_project_type
      t.integer :prior_exit_destination_id

      t.datetime :calculated_at, null: false
    end
  end
end
