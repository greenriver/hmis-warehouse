class CreateCustomImportsBCooRows < ActiveRecord::Migration[6.1]
  def change
    create_table :custom_imports_b_coo_rows do |t|

      t.string :unique_id, null: false, index: { unique: true }
      t.string :personal_id
      t.string :enrollment_id
      t.string :city
      t.string :state
      t.string :zip_code
      t.string :length_of_time
      t.string :geolocation_location
      t.date :collected_on

      t.references :import_file
      t.references :data_source

      t.timestamps
    end
  end
end
