class AddAggregatorsToDataSources < ActiveRecord::Migration[5.2]
  def change
    add_column :data_sources, :import_aggregators, :jsonb, default: {}
  end
end
