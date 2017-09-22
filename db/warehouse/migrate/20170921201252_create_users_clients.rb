class CreateUsersClients < ActiveRecord::Migration
  def change
    create_table :user_clients do |t|
      t.references :user, index: true, null: false
      t.references :client, index: true, null: false
      t.boolean :confidential, null: false, default: false
      t.string :relationship
      t.timestamps null: false
      t.datetime :deleted_at
    end
  end
end
