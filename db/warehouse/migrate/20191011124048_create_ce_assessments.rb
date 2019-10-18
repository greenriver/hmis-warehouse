class CreateCeAssessments < ActiveRecord::Migration
  def change
    create_table :ce_assessments do |t|
      t.integer :user_id, index: true, null: false
      t.integer :client_id, index: true, null: false

      t.string :type, index: true, null: false
      t.datetime :submitted_at
      t.timestamps null: false
      t.datetime :deleted_at, index: true

      t.boolean :active, default: true
      t.integer :score, default: 0
      t.integer :priority_score, default: 0

      t.integer :assessor_id, index: true, null: false
      t.string :location

      t.string :client_email

      t.boolean :military_duty, default: false
      t.boolean :under_25, default: false
      t.boolean :over_60, default: false
      t.boolean :lgbtq, default: false
      t.boolean :children_under_18, default: false
      t.boolean :fleeing_dv, default: false
      t.boolean :living_outdoors, default: false
      t.boolean :urgent_health_issue, default: false

      t.boolean :location_option_1, default: false
      t.boolean :location_option_2, default: false
      t.boolean :location_option_3, default: false
      t.boolean :location_option_4, default: false
      t.boolean :location_option_5, default: false
      t.boolean :location_option_6, default: false
      t.string :location_option_other
      t.string :location_option_no

      t.integer :homelessness
      t.integer :substance_use
      t.integer :mental_health
      t.integer :health_care
      t.integer :legal_issues
      t.integer :income
      t.integer :work
      t.integer :independent_living
      t.integer :community_involvement
      t.integer :survival_skills

      t.boolean :barrier_no_rental_history, default: false
      t.boolean :barrier_no_income, default: false
      t.boolean :barrier_poor_credit, default: false
      t.boolean :barrier_eviction_history, default: false
      t.boolean :barrier_eviction_from_public_housing, default: false
      t.boolean :barrier_bedrooms_3, default: false
      t.boolean :barrier_service_animal, default: false
      t.boolean :barrier_cori_issues, default: false
      t.boolean :barrier_registered_sex_offender, default: false
      t.string :barrier_other

      t.boolean :preferences_studio, default: false
      t.boolean :preferences_roomate, default: false
      t.boolean :preferences_pets, default: false
      t.boolean :preferences_accessible, default: false
      t.boolean :preferences_quiet, default: false
      t.boolean :preferences_public_transport, default: false
      t.boolean :preferences_parks, default: false
      t.string :preferences_other

      t.integer :assessor_rating

      t.boolean :homeless_six_months, default: false

      t.boolean :mortality_hospitilization_3, default: false
      t.boolean :mortality_emergency_room_3, default: false
      t.boolean :mortality_over_60, default: false
      t.boolean :mortality_cirrhosis, default: false
      t.boolean :mortality_renal_disease, default: false
      t.boolean :mortality_frostbite, default: false
      t.boolean :mortality_hiv, default: false
      t.boolean :mortality_tri_morbid, default: false

      t.boolean :lacks_access_to_shelter, default: false
      t.boolean :high_potential_for_vicitimization, default: false
      t.boolean :danger_of_harm, default: false
      t.boolean :acute_medical_condition, default: false
      t.boolean :acute_psychiatric_condition, default: false
      t.boolean :acute_substance_abuse, default: false

    end
  end
end
