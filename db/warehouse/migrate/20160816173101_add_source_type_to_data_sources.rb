class AddSourceTypeToDataSources < ActiveRecord::Migration[4.2]
  def change
    add_column :data_sources, :source_type, :string
  end
end
