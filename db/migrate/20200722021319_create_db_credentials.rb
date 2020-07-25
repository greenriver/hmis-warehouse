class CreateDbCredentials < ActiveRecord::Migration[5.2]
  def change
    create_table :db_credentials do |t|
      t.belongs_to :user, foreign_key: true, index: false
      t.string :role, null: false
      t.string :adaptor, null: false
      t.string :username, null: false
      t.binary :encrypted_password, null: false
      t.binary :encrypted_password_iv, null: false
      t.string :database, null: false
      t.string :host
      t.string :port
      t.timestamps
      t.index [:user_id, :role], unique: true
    end
  end
end
