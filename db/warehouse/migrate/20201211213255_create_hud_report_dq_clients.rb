class CreateHudReportDqClients < ActiveRecord::Migration[5.2]
  def change
    create_table :hud_report_dq_clients do |t|
      t.integer :client_id
      t.integer :data_source_id
      t.integer :report_instance_id

      t.index [:client_id, :data_source_id, :report_instance_id], unique: true,  name: 'dq_client_conflict_columns'

      t.integer :destination_client_id
      t.timestamps
      t.timestamp :deleted_at

      t.integer :age
      t.boolean :alcohol_abuse_entry
      t.boolean :alcohol_abuse_exit
      t.boolean :alcohol_abuse_latest
      t.boolean :annual_assessment_expected
      t.integer :approximate_length_of_stay
      t.integer :approximate_time_to_move_in
      t.integer :came_from_street_last_night
      t.boolean :chronic_disability
      t.integer :chronic_disability_entry
      t.integer :chronic_disability_exit
      t.integer :chronic_disability_latest
      t.boolean :chronically_homeless
      t.integer :currently_fleeing
      t.date :date_homeless
      t.date :date_of_engagement
      t.date :date_of_last_bed_night
      t.date :date_to_street
      t.integer :destination
      t.boolean :developmental_disability
      t.integer :developmental_disability_entry
      t.integer :developmental_disability_exit
      t.integer :developmental_disability_latest
      t.integer :disabling_condition
      t.date :dob
      t.integer :dob_quality
      t.integer :domestic_violence
      t.boolean :drug_abuse_entry
      t.boolean :drug_abuse_exit
      t.boolean :drug_abuse_latest
      t.string :enrollment_coc
      t.date :enrollment_created
      t.integer :ethnicity
      t.date :exit_created
      t.date :first_date_in_program
      t.string :first_name
      t.integer :gender
      t.boolean :head_of_household
      t.string :head_of_household_id
      t.boolean :hiv_aids
      t.integer :hiv_aids_entry
      t.integer :hiv_aids_exit
      t.integer :hiv_aids_latest
      t.string :household_id
      t.jsonb :household_members
      t.string :household_type
      t.integer :housing_assessment
      t.date :income_date_at_annual_assessment
      t.date :income_date_at_exit
      t.date :income_date_at_start
      t.integer :income_from_any_source_at_annual_assessment
      t.integer :income_from_any_source_at_exit
      t.integer :income_from_any_source_at_start
      t.jsonb :income_sources_at_annual_assessment
      t.jsonb :income_sources_at_exit
      t.jsonb :income_sources_at_start
      t.integer :income_total_at_annual_assessment
      t.integer :income_total_at_exit
      t.integer :income_total_at_start
      t.boolean :indefinite_and_impairs
      t.integer :insurance_from_any_source_at_annual_assessment
      t.integer :insurance_from_any_source_at_exit
      t.integer :insurance_from_any_source_at_start
      t.date :last_date_in_program
      t.string :last_name
      t.integer :length_of_stay
      t.boolean :mental_health_problem
      t.integer :mental_health_problem_entry
      t.integer :mental_health_problem_exit
      t.integer :mental_health_problem_latest
      t.integer :months_homeless
      t.date :move_in_date
      t.integer :name_quality
      t.integer :non_cash_benefits_from_any_source_at_annual_assessment
      t.integer :non_cash_benefits_from_any_source_at_exit
      t.integer :non_cash_benefits_from_any_source_at_start
      t.boolean :other_clients_over_25
      t.jsonb :overlapping_enrollments
      t.boolean :parenting_juvenil
      t.boolean :parenting_youth
      t.boolean :physical_disability
      t.integer :physical_disability_entry
      t.integer :physical_disability_exit
      t.integer :physical_disability_latest
      t.integer :prior_length_of_stay
      t.integer :prior_living_situation
      t.integer :project_tracking_method
      t.integer :project_type
      t.integer :race
      t.integer :relationship_to_hoh
      t.string :ssn
      t.integer :ssn_quality
      t.integer :subsidy_information
      t.boolean :substance_abuse
      t.integer :substance_abuse_entry
      t.integer :substance_abuse_exit
      t.integer :substance_abuse_latest
      t.integer :time_to_move_in
      t.integer :times_homeless
      t.integer :veteran_status
    end

    create_table :hud_report_dq_living_situations do |t|
      t.references :hud_report_dq_client, index: {name: 'index_hud_dq_client_liv_sit'}
      t.integer :living_situation
      t.date :information_date
      
      t.timestamps
      t.datetime :deleted_at
    end
  end
end
