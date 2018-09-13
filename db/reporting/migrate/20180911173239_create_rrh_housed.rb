class CreateRrhHoused < ActiveRecord::Migration
  def change
    create_table :houseds do |t|
      t.date :search_start, index: true
      t.date :search_end, index: true
      t.date :housed_date, index: true
      t.date :housing_exit, index: true
      t.integer :project_type
      t.integer :destination
      t.string :service_project
      t.string :residential_project
      t.integer :client_id, null: false, index: true
      t.string :source
      t.string :first_name
      t.string :last_name
      t.string :ssn
      t.date :dob
      t.string :race
      t.integer :ethnicity
      t.integer :gender
      t.integer :veteran_status
      t.date :month_year
      t.string :ph_destination
    end
  end
end
