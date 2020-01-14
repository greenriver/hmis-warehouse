class AddShortNamesToDataSources < ActiveRecord::Migration[4.2]
  def change
    add_column :data_sources, :short_name, :string
  end
end
