class CreateAppointments < ActiveRecord::Migration
  def change
    create_table :appointments do |t|
      t.date :appointment_date
      t.string :type
      t.text :notes
      t.string :doctor
      t.string :department
      t.string :sa
      t.timestamps null: false
      t.references :patient, index: true
    end
  end
end
