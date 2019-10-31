class AddRequiredForToAvailableFileTag < ActiveRecord::Migration[4.2]
  def change
    add_column :available_file_tags, :required_for, :string
  end
end
