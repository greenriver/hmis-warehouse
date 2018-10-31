class CreateGlacierVaults < ActiveRecord::Migration
  def change
    create_table :glacier_vaults do |t|
      t.string :name, null: false
      t.timestamp :vault_created_at
      t.timestamp :last_upload_attempt_at
      t.timestamp :last_upload_success_at
      t.timestamps null: false
    end

    add_index :glacier_vaults, :name, unique: true

    create_table :glacier_archives do |t|
      t.references :glacier_vault, foreign_key: true, null: false, index: true
      t.text :upload_id, null: false
      t.text :archive_id
      t.text :checksum
      t.text :location
      t.string :status, null: false, default: 'initialized'
      t.boolean :verified, null: false, default: false
      t.integer :size_in_bytes
      t.timestamp :upload_started_at
      t.timestamp :upload_finished_at
      t.timestamps null: false
    end

    add_index :glacier_archives, :upload_id, unique: true
  end
end
