class AddFirstAndLastNamesToUser < ActiveRecord::Migration[4.2]
  def change
    rename_column :users, :name, :last_name
    add_column :users, :first_name, :string
  end
end
