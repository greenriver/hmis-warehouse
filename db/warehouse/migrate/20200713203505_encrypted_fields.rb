class EncryptedFields < ActiveRecord::Migration[5.2]
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

    [
      :encrypted_FirstName,
      :encrypted_FirstName_iv,
      :encrypted_MiddleName,
      :encrypted_MiddleName_iv,
      :encrypted_LastName,
      :encrypted_LastName_iv,
      :encrypted_SSN,
      :encrypted_SSN_iv,
      :encrypted_NameSuffix,
      :encrypted_NameSuffix_iv,
    ].each do |column_name|
      add_column :Client, column_name, :string
    end
  end
end
