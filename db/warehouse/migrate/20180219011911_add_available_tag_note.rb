class AddAvailableTagNote < ActiveRecord::Migration[4.2]
  def change
    add_column :available_file_tags, :note, :string
  end
end
