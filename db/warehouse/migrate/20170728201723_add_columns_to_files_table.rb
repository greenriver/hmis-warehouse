class AddColumnsToFilesTable < ActiveRecord::Migration[4.2]
  def change
    add_column :files, :note, :string
    add_column :files, :name, :string
    add_column :files, :visible_in_window, :boolean
  end
end
