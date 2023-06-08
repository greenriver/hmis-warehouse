class ProjectsImportTracking < ActiveRecord::Migration[6.1]
  def change
    create_table :ac_hmis_projects_import_attempts do |t|
      t.string :status, null: false, default: 'init'
      t.string :etag, null: false, comment: 'fingerprint of the file'
      t.text :key, null: false, comment: 'path in an s3 bucket to the file'
      t.jsonb :result, null: false, default: {}
      t.datetime :attempted_at, null: false, comment: 'last time an import was attempted'
      # t.datetime :ignored_at, comment: 'set if imports should not be attempted'
    end

    safety_assured do
      add_index :ac_hmis_projects_import_attempts, [:key, :etag], unique: true
      add_index :ac_hmis_projects_import_attempts, :etag
    end
  end
end
