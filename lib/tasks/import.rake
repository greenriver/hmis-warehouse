namespace :import do
  task :remote_data, [] => [:environment] do
    tasks = []

    if HmisEnforcement.hmis_enabled? && GrdaWarehouse::DataSource.hmis.exists?
      # Fetch recent client changes from AC Data Warehouse to get MCI Unique IDs
      tasks << 'driver:hmis_external_apis:import:ac_warehouse_changes' if RailsDrivers.loaded.include?(:hmis_external_apis)
    end

    tasks << 'eto:import:demographics_and_touch_points'

    tasks.each do |task|
      Rake::Task[task].invoke
    end
  end
end
