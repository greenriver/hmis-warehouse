class CreateSystemPathwaysReports < ActiveRecord::Migration[6.1]
  def change
    create_table :system_pathways_clients do |t|
      t.references :client
      t.string :first_name
      t.string :last_name
      t.string :personal_ids
      t.date :dob
      t.integer :age
      t.boolean :am_ind_ak_native
      t.boolean :asian
      t.boolean :black_af_american
      t.boolean :native_hi_pacific
      t.boolean :white
      t.integer :ethnicity
      t.boolean :male
      t.boolean :female
      t.boolean :gender_other
      t.boolean :transgender
      t.boolean :questioning
      t.boolean :no_single_gender
      t.boolean :disabling_condition
      t.integer :relationship_to_hoh
      t.integer :veteran_status
      t.string :household_id
      t.string :household_type
      t.boolean :ce
      t.boolean :system
      t.boolean :es
      t.boolean :sh
      t.boolean :th
      t.boolean :rrh
      t.boolean :psh
      t.boolean :oph
      t.boolean :ph
      t.integer :destination
      t.integer :returned
      t.timestamps
    end
  end
end
