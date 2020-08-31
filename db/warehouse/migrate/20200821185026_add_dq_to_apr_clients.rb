class AddDqToAprClients < ActiveRecord::Migration[5.2]
  def change
    change_table :hud_report_apr_clients do |t|
      t.string :first_name
      t.string :last_name
      t.integer :name_quality
      t.string :ssn
      t.integer :ssn_quality
      t.date :dob
      t.integer :dob_quality
      t.date :enrollment_created
      t.jsonb :race
      t.integer :ethnicity
      t.integer :gender
      t.jsonb :overlapping_enrollments
      t.integer :relationship_to_hoh
      t.string :household_id
      t.string :enrollment_coc
      t.integer :disabling_condition
      t.boolean :developmental_disability
      t.boolean :hiv_aids
      t.boolean :physical_disability
      t.boolean :chronic_disability
      t.boolean :mental_health_problem
      t.boolean :substance_abuse
      t.boolean :indefinite_and_impairs
    end
  end
end
