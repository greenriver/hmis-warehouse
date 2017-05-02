class CreateUploads < ActiveRecord::Migration
  def up
    create_table :uploads do |t|
      t.references :data_source
      t.string :file_name, null: false
      t.float :percent_complete
      t.string :unzipped_path
      t.json :unzipped_files
      t.json :summary
      t.json :import_errors
      t.timestamps null: false
      t.datetime :started_at
      t.datetime :completed_at
      t.datetime :deleted_at, index: true, null: true
    end

    Role.ensure_permissions_exist

    admin = Role.where(name: 'admin').first_or_create
    dnd = Role.where(name: 'dnd_staff').first_or_create
    admin.update(can_upload_hud_zips: true)
    dnd.update(can_upload_hud_zips: true)
  end

  def down
    drop_table :uploads
    remove_column :roles, :can_upload_hud_zips, :boolean, default: false
  end
end
