class CreateHmisCsvLoadErrors < ActiveRecord::Migration[5.2]
  def change
    create_table :hmis_csv_load_errors do |t|
      t.integer :loader_log_id, null: false, index: true
      t.string :file_name, null: false
      t.string :message
      t.string :details
      t.string :source
    end
  end
end
