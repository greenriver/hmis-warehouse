class AppointmentIndexes < ActiveRecord::Migration[6.1]
  def change
    StrongMigrations.disable_check(:add_index)
    add_index :epic_patients, :id_in_source
    add_index :appointments, :department
    add_index :epic_patients, :medicaid_id
    add_index :appointments, :appointment_time
    safety_assured do
      execute('analyze  appointments, epic_patients;')
    end
  ensure
    StrongMigrations.enable_check(:add_index)
  end
end
