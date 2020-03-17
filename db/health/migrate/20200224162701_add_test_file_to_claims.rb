class AddTestFileToClaims < ActiveRecord::Migration[5.2]
  def change
    add_column :claims, :test_file, :boolean, default: false
  end
end
