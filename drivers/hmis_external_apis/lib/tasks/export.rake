namespace :export do
  # ./bin/rake driver:hmis_external_apis:export:ac_clients
  desc 'Export AC client data'
  task :ac_clients, [] => [:environment] do
    next unless HmisExternalApis::AcHmis::Exporters::DataWarehouseUploader.can_run?
    next unless HmisEnforcement.hmis_enabled?
    next unless GrdaWarehouse::DataSource.hmis.exists?

    [
      'clients_with_mci_ids_and_address',
      'hmis_csv_export',
      'project_crosswalk',
      'move_in_addresses',
      'postings',
      'pathways',
    ].each do |export_mode|
      HmisExternalApis::AcHmis::DataWarehouseUploadJob.perform_later(export_mode)
    end
  end
end
