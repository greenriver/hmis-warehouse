class CreateRemoteConfigs < ActiveRecord::Migration[6.1]
  def change
    create_table :remote_configs do |t|
      t.string :type, null: false
      t.boolean :active, default: false
      t.string :username, null: false, comment: 'username or equivalent eg. s3_access_key_id'
      t.string :encrypted_password, null: false, comment: 'password or equivalent eg. s3_secret_access_key'
      t.string :encrypted_password_iv
      t.string :region
      t.string :bucket
      t.string :path
      t.string :endpoint

      t.timestamps
    end
  end
end
