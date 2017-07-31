class AddColumnsToFilesTable < ActiveRecord::Migration
  def change
    add_column :files, :note, :string
    add_column :files, :name, :string
    add_column :files, :visible_in_window, :boolean
  end
end
