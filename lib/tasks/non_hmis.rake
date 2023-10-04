namespace :dashboard do
  desc 'Ingest code for additional non-HMIS Export; params: data_source_id, file=var/import/non_hmis.xls'
  # Example: bin/rake dashboard:import_enrollment_extras data_source_id=1
  task import_enrollment_extras: [:environment] do
    data_source_id = ENV['data_source_id'].presence || raise('no data_source_id provided')

    # verify that this data source exists
    data_source_id = GrdaWarehouse::DataSource.find(data_source_id).id
    file = ENV['file'].presence || 'var/import/non_hmis.xls'
    task = GrdaWarehouse::Tasks::EnrollmentExtrasImport.new source: file, data_source_id: data_source_id
    task.run!
  end
end
