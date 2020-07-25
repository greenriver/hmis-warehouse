class CreateAwsCredentials < ActiveRecord::Migration[5.2]
  def change
    create_table :aws_credentials do |t|
      t.belongs_to :user, foreign_key: true
      t.string :account_id, null: false
      t.string :username, null: false
      t.string :access_key_id, null: false
      t.binary :encrypted_secret_access_key, null: false
      t.binary :encrypted_secret_access_key_iv, null: false
      t.timestamps
    end
  end
end
