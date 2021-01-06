class RenameRequired < ActiveRecord::Migration[5.2]
  def change
    rename_column :access_groups, :required, :must_exist
  end
end
