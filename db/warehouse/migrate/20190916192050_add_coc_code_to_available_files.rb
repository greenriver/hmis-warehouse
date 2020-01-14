class AddCoCCodeToAvailableFiles < ActiveRecord::Migration[4.2]
  def change
    add_column :available_file_tags, :coc_available, :boolean, default: false, null: false
    add_column :files, :coc_code, :string, length: 6
  end
end
