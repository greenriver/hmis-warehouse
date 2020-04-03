class CreateTracingTables < ActiveRecord::Migration[5.2]
  def change
    create_table :tracing_cases do |t|
      t.integer :client_id, index: true

      t.string :health_emergency, null: false

      t.string :investigator
      t.date :date_listed
      t.string :alert_in_epic
      t.string :complete

      t.date :date_interviewed
      t.date :infectious_start_date
      t.date :testing_date
      t.date :isolation_start_date

      t.string :first_name
      t.string :last_name
      t.jsonb :aliases
      t.date :dob
      t.integer :gender
      t.jsonb :race
      t.integer :ethnicity
      t.string :preferred_language

      t.string :occupation
      t.string :recent_incarceration
      t.string :notes

      t.timestamp :deleted_at
      t.timestamps
    end

    create_table :tracing_contacts do |t|
      t.references :case

      t.date :date_interviewed
      t.string :first_name
      t.string :last_name
      t.jsonb :aliases
      t.string :phone_number
      t.string :address # Use locations?
      t.date :dob
      t.string :estimated_age
      t.integer :gender
      t.jsonb :race
      t.integer :ethnicity
      t.string :preferred_language

      t.string :relationship_to_index_case
      t.string :location_of_exposure # Use locations?
      t.string :nature_of_exposure
      t.string :location_of_contact # Use locations?
      t.string :sleeping_location #Use locations?

      t.string :symtomatic
      t.date :symptom_onset_date
      t.string :referred_for_testing
      t.string :test_result
      t.string :isolated
      t.string :isolation_location # Use locations?
      t.string :quarantine
      t.string :quarantine_location # Use locations?
      t.string :notes

      t.timestamp :deleted_at
      t.timestamps
    end

    create_table :tracing_locations do |t|
      t.references :case

      t.string :location

      t.timestamp :deleted_at
      t.timestamps
    end

    create_table :tracing_site_leaders do |t|
      t.references :case

      t.string :site_name
      t.string :site_leader_name
      t.date :contacted_on

      t.timestamp :deleted_at
      t.timestamps
    end

    create_table :tracing_staffs do |t|
      t.references :case

      t.date :date_interviewed
      t.string :first_name
      t.string :last_name
      t.string :site_name
      t.string :nature_of_exposure
      t.string :symtomatic
      t.string :referred_for_testing
      t.string :test_result
      t.string :notes

      t.timestamp :deleted_at
      t.timestamps
    end
  end
end
