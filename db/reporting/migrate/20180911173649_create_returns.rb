class CreateReturns < ActiveRecord::Migration
  def change
    create_table :returns do |t|
      t.integer :service_history_enrollment_id, null: false, index: true
      t.string :record_type, null: false, index: true
      t.date :date
      t.integer :date
      t.integer :service_type, index: true
      t.integer :client_id, null: false, index: true
      t.integer :project_type, index: true
      t.date :first_date_in_program, null: false, index: true
      t.date :last_date_in_program
      t.integer :project_id
      t.integer :destination
      t.string :project_name
      t.integer :organization_id
      t.boolean :unaccompaine_youth
      t.boolean :parenting_youth
    end
  end
end
