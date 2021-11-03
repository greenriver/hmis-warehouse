class CreateImportConfigs < ActiveRecord::Migration[5.2]
  def change
    create_table :import_configs do |t|
      t.string :name
      t.string :host
      t.string :path
      t.string :username
      t.string :encrypted_password
      t.string :encrypted_password_iv
      t.string :destination
      t.string :data_source_name
    end
  end
end
