namespace :export do
  # ./bin/rake driver:hmis_external_apis:export:ac_clients
  desc 'Export AC client data'
  task :ac_clients, [] => [:environment] do
    next unless HmisExternalApis::AcHmis::Exporters::DataWarehouseUploader.can_run?
    next unless HmisEnforcement.hmis_enabled?
    next unless GrdaWarehouse::DataSource.hmis.exists?

    HmisExternalApis::AcHmis::DataWarehouseUploadJob.perform_later('clients_with_mci_ids_and_address')
    HmisExternalApis::AcHmis::DataWarehouseUploadJob.perform_later('hmis_csv_export')
    HmisExternalApis::AcHmis::DataWarehouseUploadJob.perform_later('project_crosswalk')
  end
end
