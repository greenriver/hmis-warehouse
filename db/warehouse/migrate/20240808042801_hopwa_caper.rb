class HopwaCaper < ActiveRecord::Migration[7.0]
  def change
    create_table :hopwa_caper_enrollments do |t|
      t.references :report_instance, null: false
      t.references :destination_client, null: false
      t.references :enrollment, index: false, null: false
      t.string :report_household_id, null: false, index: true

      # for reference by cell members reporting view
      t.string :first_name
      t.string :last_name
      t.string :personal_id, null: false

      # demographics
      t.integer :age
      t.date :dob
      t.integer :dob_quality
      t.integer :genders, array: true
      t.integer :races, array: true
      t.boolean :veteran, null: false, default: false

      t.date :entry_date
      t.date :exit_date
      t.integer :relationship_to_hoh, null: false

      t.integer :project_funders, array: true
      t.string :project_type

      t.string :income_benefit_source_types, array: true
      t.string :medical_insurance_types, array: true

      t.boolean :hiv_positive, null: false, default: false
      t.boolean :hopwa_eligible, null: false, default: false
      t.boolean :chronically_homeless, null: false, default: false
      t.integer :prior_living_situation
      t.integer :rental_subsidy_type
      t.integer :exit_destination
      t.integer :duration_days
      t.integer :housing_assessment_at_exit
      t.integer :subsidy_information
      t.boolean :ever_prescribed_anti_retroviral_therapy, null: false, default: false
      t.boolean :viral_load_suppression, null: false, default: false

      t.numeric :percent_ami

      t.index [:report_instance_id, :enrollment_id], unique: true, name: 'uidx_hopwa_caper_enrollments'
    end

    create_table :hopwa_caper_services do |t|
      t.references :report_instance, null: false
      t.references :destination_client, null: false
      t.references :enrollment, index: false, null: false
      t.references :service, index: false, null: false
      t.string :report_household_id, null: false, index: true
      t.string :personal_id, null: false
      t.date :date_provided
      t.integer :record_type
      t.integer :type_provided
      t.numeric :fa_amount
      t.index [:report_instance_id, :service_id], unique: true, name: 'uidx_hopwa_caper_services'
    end
  end
end
