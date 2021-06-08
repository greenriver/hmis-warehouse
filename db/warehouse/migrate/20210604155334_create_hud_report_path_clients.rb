class CreateHudReportPathClients < ActiveRecord::Migration[5.2]
  def change
    create_table :hud_report_path_clients do |t|
      t.references :client
      t.references :report_instance
      t.string :first_name
      t.string :last_name

      t.integer :age
      t.date :dob
      t.integer :dob_quality
      t.integer :gender
      t.integer :am_ind_ak_native
      t.integer :asian
      t.integer :black_af_american
      t.integer :native_hi_other_pacific
      t.integer :white
      t.integer :race_none
      t.integer :ethnicity
      t.integer :veteran
      t.integer :substance_use_disorder
      t.integer :soar
      t.integer :prior_living_situation
      t.integer :length_of_stay
      t.string :chronically_homeless
      t.integer :domestic_violence

      t.boolean :active_client
      t.boolean :new_client
      t.boolean :enrolled_client
      t.date :date_of_determination
      t.integer :reason_not_enrolled

      t.integer :project_type
      t.date :first_date_in_program
      t.date :last_date_in_program

      t.jsonb :contacts # an array of contact dates
      t.jsonb :services # a hash of dates to services on that day
      t.jsonb :referrals # a hash of dates to referrals and outcomes on that day

      t.integer :income_from_any_source_entry
      t.jsonb :incomes_at_entry
      t.integer :income_from_any_source_exit
      t.jsonb :incomes_at_exit
      t.integer :income_from_any_source_report_end
      t.jsonb :incomes_at_report_end

      t.integer :destination

      t.timestamps
    end
  end
end
