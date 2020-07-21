class EncryptionSecrets < ActiveRecord::Migration[5.2]
  def change
    create_table :encryption_secrets do |t|
      t.string :version_stage, null: false
      t.string :version_id, null: false
      t.boolean :previous, default: true, null: false
      t.boolean :current, default: true, null: false
      t.timestamp :rotated_at
      t.timestamps
    end

    add_index :encryption_secrets, :version_stage, unique: true
    add_index :encryption_secrets, :version_id, unique: true
  end
end
