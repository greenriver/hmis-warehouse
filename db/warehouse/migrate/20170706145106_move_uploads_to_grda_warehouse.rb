class MoveUploadsToGrdaWarehouse < ActiveRecord::Migration
  def change
    create_table :uploads do |t|
      t.references :data_source
      t.references :user
      t.string :file, null: false
      t.float :percent_complete
      t.string :unzipped_path
      t.json :unzipped_files
      t.json :summary
      t.json :import_errors
      t.string :content_type
      t.binary :content
      t.timestamps null: false
      t.datetime :started_at
      t.datetime :completed_at
      t.datetime :deleted_at, index: true, null: true
    end
  end
end
