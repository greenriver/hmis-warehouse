class AddFileTagConfig < ActiveRecord::Migration
  def change
    add_column :configs, :allow_multiple_file_tags, :boolean, null: false, default: false
  end
end
