class AddSourceTypeToDataSources < ActiveRecord::Migration
  def change
    add_column :data_sources, :source_type, :string
  end
end
