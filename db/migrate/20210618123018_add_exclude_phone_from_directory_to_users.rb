class AddExcludePhoneFromDirectoryToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :exclude_phone_from_directory, :boolean, default: false
  end
end
