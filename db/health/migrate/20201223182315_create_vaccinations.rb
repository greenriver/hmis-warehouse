class CreateVaccinations < ActiveRecord::Migration[5.2]
  def change
    create_table :vaccinations do |t|
      t.integer :client_id
      t.string :epic_patient_id, null: false
      t.string :medicaid_id
      t.string :first_name
      t.string :last_name
      t.date :dob
      t.string :ssn
      t.date :vaccinated_on, null: false
      t.string :vaccinated_at
      t.string :vaccination_type, null: false
      t.string :follow_up_cell_phone
      t.boolean :existed_previously, default: false, null: false
      t.integer :data_source_id
      t.timestamps null: false, index: true
      t.datetime :deleted_at
    end
    add_index :vaccinations, [:epic_patient_id, :vaccinated_on], unique: true
  end
end
