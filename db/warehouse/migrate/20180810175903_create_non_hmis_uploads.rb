class CreateNonHmisUploads < ActiveRecord::Migration
  def up
    create_table :non_hmis_uploads do |t|
      t.references :data_source
      t.references :user
      t.references :delayed_job
      t.string :file, null: false
      t.float :percent_complete
      t.json :import_errors
      t.string :content_type
      t.binary :content
      t.timestamps null: false
      t.datetime :started_at
      t.datetime :completed_at
      t.datetime :deleted_at, index: true, null: true
    end

  end

  def down
    drop_table :non_hmis_uploads
  end
end
