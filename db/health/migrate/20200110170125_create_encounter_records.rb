class CreateEncounterRecords < ActiveRecord::Migration[5.2]
  def change
    create_table :encounter_records do |t|
      t.references :encounter_report
      t.string :medicaid_id
      t.date :date
      t.string :provider_name
      t.boolean :contact_reached
      t.string :mode_of_contact
      t.date :dob
      t.string :gender
      t.string :race
      t.string :ethnicity
      t.string :veteran_status
      t.string :housing_status
      t.string :source
      t.string :encounter_type

      t.timestamps
    end
  end
end
