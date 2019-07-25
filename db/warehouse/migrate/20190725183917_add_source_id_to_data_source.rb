class AddSourceIdToDataSource < ActiveRecord::Migration
  def change
    add_column :data_sources, :source_id, :string
  end
end
