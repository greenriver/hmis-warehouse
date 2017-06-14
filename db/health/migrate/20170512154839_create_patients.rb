class CreatePatients < ActiveRecord::Migration
  def change
    create_table :patients do |t|
      t.string :import_pk, null: false
      t.integer :gender, null: false, default: 99   # 99 is "data not collected" per controlled vocabulary 3.6.1
      t.string :first_name
      t.string :middle_name
      t.string :last_name
      t.text :aliases
      t.date :birthdate
      t.text :allergy_list
      t.string :primary_care_physician
      t.string :transgender
      t.string :race
      t.string :ethnicity
      t.string :veteran_status
      t.string :ssn
      t.timestamps null: false
    end
  end
end
