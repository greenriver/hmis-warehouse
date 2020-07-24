class CreateScannerIds < ActiveRecord::Migration[5.2]
  def change
    create_table :service_scanning_scanner_ids do |t|
      t.references :client, null: false, index: true
      t.string :source_type, null: false, index: true
      t.string :scanned_id, null: false, index: true
      t.timestamps null: false, index: true
      t.datetime :deleted_at
    end

    create_table :service_scanning_services do |t|
      t.references :client, null: false, index: true
      t.references :project, null: false, index: true
      t.references :user, null: false
      t.string :type, null: false, index: true
      t.string :other_type
      t.datetime :provided_at
      t.string :note
      t.timestamps null: :false, index: true
      t.datetime :deleted_at
    end

    add_column :client_notes, :alert_active, :boolean, null: false, default: true
  end
end
