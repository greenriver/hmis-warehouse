class AddRequiredForToAvailableFileTag < ActiveRecord::Migration
  def change
    add_column :available_file_tags, :required_for, :string
  end
end
