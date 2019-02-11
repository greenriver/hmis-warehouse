class AddAfterCreatePathToDataSource < ActiveRecord::Migration
  def change
    add_column :data_sources, :after_create_path, :string
  end
end
