class AddAfterCreatePathToDataSource < ActiveRecord::Migration[4.2]
  def change
    add_column :data_sources, :after_create_path, :string
  end
end
