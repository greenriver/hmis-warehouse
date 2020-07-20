class AddPiiEncryptionType < ActiveRecord::Migration[5.2]
  def change
    add_column :configs, :pii_encryption_type, :string, default: :none
    add_column :configs, :auto_de_duplication_enabled, :boolean, null: false, default: false
  end
end
