class AddExcludeFromDirectoryToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :exclude_from_directory, :boolean, default: false
  end
end
