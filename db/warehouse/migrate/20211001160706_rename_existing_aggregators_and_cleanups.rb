class RenameExistingAggregatorsAndCleanups < ActiveRecord::Migration[5.2]
  def up
    ds_with_cleanups = GrdaWarehouse::DataSource.where.not(import_cleanups: {})

    ds_with_cleanups.each do |data_source|
      cleanup_map = data_source.import_cleanups
      cleanup_map.transform_values! do |cleanup_names|
        cleanup_names.map! { |name| name.gsub(/HmisCsvTwentyTwenty::/, 'HmisCsvImporter::')}
      end
      data_source.save!
    end

    ds_with_aggregations = GrdaWarehouse::DataSource.where.not(import_aggregators: {})

    ds_with_aggregations.each do |data_source|
      aggregator_map = data_source.import_aggregators
      aggregator_map.transform_values! do |aggregator_names|
        aggregator_names.map! { |name| name.gsub(/HmisCsvTwentyTwenty::/, 'HmisCsvImporter::')}
      end
      data_source.save!
    end
  end

  def down
    ds_with_cleanups = GrdaWarehouse::DataSource.where.not(import_cleanups: {})

    ds_with_cleanups.each do |data_source|
      cleanup_map = data_source.import_cleanups
      cleanup_map.transform_values! do |cleanup_names|
        cleanup_names.map! { |name| name.gsub(/HmisCsvImporter::/, 'HmisCsvTwentyTwenty::')}
      end
      data_source.save!
    end

    ds_with_aggregations = GrdaWarehouse::DataSource.where.not(import_aggregators: {})

    ds_with_aggregations.each do |data_source|
      aggregator_map = data_source.import_aggregators
      aggregator_map.transform_values! do |aggregator_names|
        aggregator_names.map! { |name| name.gsub(/HmisCsvImporter::/, 'HmisCsvTwentyTwenty::')}
      end
      data_source.save!
    end
  end
end
