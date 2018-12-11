class CreateTokens < ActiveRecord::Migration
  def change
    create_table :tokens do |t|
      t.timestamps null: false, index: true
      t.string :token, null: false, index: true
      t.string :path, null: false
      t.datetime :expires_at, index: true
    end
  end
end
