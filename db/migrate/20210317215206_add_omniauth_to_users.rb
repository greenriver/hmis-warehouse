class AddOmniauthToUsers < ActiveRecord::Migration[5.2]
  def up

    add_column(:users, :provider, :string) unless column_exists? :users, :provider
    add_column(:users, :uid, :string) unless column_exists? :users, :uid
    add_index(:users, [:uid, :provider], unique: true) unless index_exists?(:users, [:uid, :provider])
  end

  def down
    remove_column :users, :provider, :string unless
    remove_column :users, :uid, :string
  end
end
