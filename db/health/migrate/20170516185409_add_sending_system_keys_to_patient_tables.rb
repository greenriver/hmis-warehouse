class AddSendingSystemKeysToPatientTables < ActiveRecord::Migration
  def change
    remove_column :appointments, :appointment_date, :date
    add_column :appointments, :appointment_time, :datetime
    add_column :appointments, :id_in_source, :string
    add_column :medications, :id_in_source, :string
    add_column :problems, :id_in_source, :string

    create_table :recent_visits do |t|
      t.date :date_of_service
      t.string :department
      t.string :facility_type
      t.string :provider
      t.string :id_in_source
      t.timestamps null: false
      t.references :patient, index: true
    end
    
  end
end
