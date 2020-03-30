class CreateHealthEmergencyTables < ActiveRecord::Migration[5.2]
  def change
    create_table :health_emergency_triages do |t|
      t.integer :user_id, null: false, index: true
      t.integer :client_id, null: false, index: true
      t.integer :agency_id, null: false, index: true
      t.string :location
      t.string :exposure
      t.string :symptoms
      t.date :first_symptoms_on
      t.date :referred_on
      t.string :referred_to

      t.timestamps null: false, index: true
      t.datetime :deleted_at
    end
    create_table :health_emergency_tests do |t|
      t.integer :user_id, null: false, index: true
      t.integer :client_id, null: false, index: true
      t.integer :agency_id, null: false, index: true
      t.string :test_requested
      t.string :location
      t.date :tested_on
      t.string :result

      t.timestamps null: false, index: true
      t.datetime :deleted_at
    end
    create_table :health_emergency_isolations do |t|
      t.string :type, null: false
      t.integer :user_id, null: false, index: true
      t.integer :client_id, null: false, index: true
      t.integer :agency_id, null: false, index: true
      t.datetime :isolation_requested_at
      t.string :location
      t.date :started_on
      t.date :scheduled_to_end_on
      t.date :ended_on

      t.timestamps null: false, index: true
      t.datetime :deleted_at
    end
  end
end
