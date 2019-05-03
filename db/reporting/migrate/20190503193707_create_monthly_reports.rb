class CreateMonthlyReports < ActiveRecord::Migration
  def change
    create_table :monthly_reports do |t|
      t.integer :month, null: false, index: true
      t.integer :year, null: false, index: true, index: true
      t.string :sub_population, index: true
      t.integer :client_id, null: false
      t.integer :head_of_household, null: false, default: 0, index: true
      t.string :household_id, index: true
      t.integer :destination_id
      t.boolean :enrolled, null: false, default: false, index: true
      t.boolean :active, null: false, default: false, index: true, index: true
      t.boolean :entered, null: false, default: false, index: true
      t.boolean :exited, null: false, default: false, index: true
      t.integer :project_type, null: false
      t.integer :days_since_last_entry
      t.integer :prior_entry_project_type

      t.datetime :calculated_at, null: false
    end
  end
end
