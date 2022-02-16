class CreatePitClients < ActiveRecord::Migration[6.1]
  def change
    create_table :hud_report_pit_clients do |t|
      t.references :client
      t.references :data_source
      t.references :report_instance
      t.string :first_name
      t.string :last_name

      t.index [:report_instance_id, :data_source_id, :client_id], unique: true, name: 'hud_pit_client_conflict_columns'

      t.integer :age
      t.date :dob
      t.integer :relationship_to_hoh
      t.integer :female
      t.integer :male
      t.integer :no_single_gender
      t.integer :transgender
      t.integer :questioning
      t.integer :gender_none
      t.integer :am_ind_ak_native
      t.integer :asian
      t.integer :black_af_american
      t.integer :native_hi_other_pacific
      t.integer :white
      t.integer :race_none
      t.integer :ethnicity
      t.integer :veteran
      t.boolean :chronically_homeless
      t.boolean :chronically_homeless_household
      t.integer :substance_use
      t.integer :substance_use_indefinite_impairing
      t.integer :domestic_violence
      t.integer :domestic_violence_currently_fleeing
      t.integer :hiv_aids
      t.integer :hiv_aids_indefinite_impairing
      t.integer :mental_illness
      t.integer :mental_illness_indefinite_impairing


      t.integer :project_type
      t.string :project_name
      t.date :first_date_in_program
      t.date :last_date_in_program

      t.timestamps
    end
  end
end
