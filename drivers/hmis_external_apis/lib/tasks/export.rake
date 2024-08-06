namespace :export do
  # ./bin/rake driver:hmis_external_apis:export:ac_clients
  desc 'Export AC client data'
  task :ac_clients, [] => [:environment] do
    next unless HmisExternalApis::AcHmis::Exporters::DataWarehouseUploader.can_run?
    next unless HmisEnforcement.hmis_enabled?
    next unless GrdaWarehouse::DataSource.hmis.exists?

    # Daily uploads to AC Data Warehouse
    HmisExternalApis::AcHmis::DataWarehouseUploadJob.perform_later('daily_uploads')

    # Quarterly upload to AC Data Warehouse (10-year lookback HMIS CSV)
    today = Date.current
    HmisExternalApis::AcHmis::DataWarehouseUploadJob.perform_later('quarterly_uploads') if today == today.beginning_of_quarter
  end
end
