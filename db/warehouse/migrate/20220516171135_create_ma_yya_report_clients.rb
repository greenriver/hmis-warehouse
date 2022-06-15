class CreateMaYyaReportClients < ActiveRecord::Migration[6.1]
  def change
    create_table :ma_yya_report_clients do |t|
      t.references :client
      t.references :service_history_enrollment
      t.date :entry_date

      t.integer :referral_source
      t.boolean :currently_homeless
      t.boolean :at_risk_of_homelessness
      t.boolean :initial_contact

      t.boolean :direct_assistance

      t.integer :current_school_attendance
      t.integer :current_educational_status

      t.integer :age
      t.integer :gender

      t.integer :race
      t.integer :ethnicity

      t.boolean :mental_health_disorder
      t.boolean :substance_use_disorder
      t.boolean :physical_disability
      t.boolean :developmental_disability
      t.boolean :pregnant
      t.date :due_date
      t.boolean :head_of_household
      t.jsonb :household_ages # Array of the ages of the household members during the reporting period
      t.integer :sexual_orientation
      t.integer :most_recent_education_status
      t.boolean :health_insurance

      t.jsonb :subsequent_current_living_situations # Array of CLS (4.12) within the reporting period and at least 90 days after the enrollment EntryDate

      t.boolean :reported_previous_period

      t.datetime :deleted_at
      t.timestamps
    end
  end
end
