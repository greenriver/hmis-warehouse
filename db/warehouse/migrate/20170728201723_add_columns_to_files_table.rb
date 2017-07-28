class AddColumnsToFilesTable < ActiveRecord::Migration
  def change
    add_column :files, :note, :string
    add_column :files, :name, :string
  end
end
