class CreateTableHudPerformanceUnduplicatedClientsNew < ActiveRecord::Migration
  def change
    create_table :client_service_history, id: false do |t|
      t.integer :unduplicated_client_id
      t.date :date
      t.date :first_date_in_program
      t.date :last_date_in_program
      t.string :program_group_id
      t.integer :program_type
      t.integer :program_id
      t.integer :age
      t.decimal :income
      t.integer :income_type
      t.integer :income_source_code
      t.integer :destination
      t.string  :head_of_household_id
      t.string :household_id
      t.string :database_id
      t.string :program_name
      t.integer :program_tracking_method
      t.string :record_type
      t.integer :dc_id
      t.integer :housing_status_at_entry
      t.integer :housing_status_at_exit
    end
  end
end
