class AddFirstAndLastNamesToUser < ActiveRecord::Migration
  def change
    rename_column :users, :name, :last_name
    add_column :users, :first_name, :string
  end
end
