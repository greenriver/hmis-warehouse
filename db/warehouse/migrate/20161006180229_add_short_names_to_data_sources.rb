class AddShortNamesToDataSources < ActiveRecord::Migration
  def change
    add_column :data_sources, :short_name, :string
  end
end
