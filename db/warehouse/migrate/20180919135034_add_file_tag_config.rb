class AddFileTagConfig < ActiveRecord::Migration[4.2]
  def change
    add_column :configs, :allow_multiple_file_tags, :boolean, null: false, default: false
  end
end
