class CreateYouthIntake < ActiveRecord::Migration
  def change
    create_table :youth_intakes do |t|

      t.references :client
      t.references :user
      t.string :type
      t.boolean :other_staff_completed_intake, null: false, default: false
      t.date :client_dob
      t.string :staff_name
      t.string :staff_email
      t.date :engagement_date, null: false
      t.date :exit_date
      t.string :unaccompanied, null: false
      t.string :street_outreach_contact, null: false
      t.string :housing_status, null: false
      t.string :other_agency_involvement, null: false
      t.string :owns_cell_phone, null: false
      t.string :secondary_education, null: false
      t.string :attending_college, null: false
      t.string :health_insurance, null: false
      t.boolean :requesting_financial_assistance, null: false
      t.boolean :staff_believes_youth_under_24, null: false
      t.integer :client_gender, null: false
      t.string :client_lbgtq, null: false
      t.jsonb :client_race, null: false
      t.integer :client_ethnicity, null: false
      t.string :client_primary_language, null: false
      t.string :pregnant_or_parenting, null: false
      t.jsonb :disabilities, null: false
      t.string :how_hear
      t.string :needs_shelter, null: false
      t.boolean :referred_to_shelter, null: false, default: false
      t.string :in_stable_housing, null: false
      t.string :stable_housing_zipcode
      t.string :youth_experiencing_homelessness_at_start

      t.timestamps null: false, index: true
      t.datetime :deleted_at, index: true

    end
  end
end
