class ConvertDataSourceConfigToImportThreshold < ActiveRecord::Migration[7.0]
  def up
    GrdaWarehouse::DataSource.where(refuse_imports_with_errors: true).find_each do |ds|
      # Create and update in individual queries, DS count should never be more than 50
      threshold = ds.import_threshold || GrdaWarehouse::ImportThreshold.new(data_source_id: ds.id)
      threshold.error_count_min_threshold ||= 0
      threshold.error_percent_threshold ||= 0
      threshold.pause_on_error_threshold = true
      threshold.save!
      ds.update(refuse_imports_with_errors: false)
    end
  end

  def down
    ds_ids = GrdaWarehouse::ImportThreshold.
      where.not(error_count_min_threshold: nil, error_percent_threshold: nil, pause_on_error_threshold: true).
      pluck(:data_source_id)
    GrdaWarehouse::DataSource.where(id: ds_ids).update_all(refuse_imports_with_errors: true)
  end
end
