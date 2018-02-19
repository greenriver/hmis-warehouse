class AddAvailableTagNote < ActiveRecord::Migration
  def change
    add_column :available_file_tags, :note, :string
  end
end
