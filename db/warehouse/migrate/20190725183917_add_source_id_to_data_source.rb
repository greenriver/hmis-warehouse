class AddSourceIdToDataSource < ActiveRecord::Migration[4.2]
  def change
    add_column :data_sources, :source_id, :string
  end
end
