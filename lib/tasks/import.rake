namespace :import do
  task :remote_data, [] => [:environment] do
    tasks = []

    if ENV['ENABLE_HMIS_API'] == 'true'
      tasks << 'driver:hmis_external_apis:import:ac_projects' if RailsDrivers.loaded.include?(:hmis_external_apis)
      tasks << 'driver:hmis_external_apis:import:ac_clients_with_active_referrals' if RailsDrivers.loaded.include?(:hmis_external_apis)
      tasks << 'driver:hmis_external_apis:export:ac_clients' if RailsDrivers.loaded.include?(:hmis_external_apis)
    end

    tasks << 'eto:import:demographics_and_touch_points'

    tasks.each do |task|
      Rake::Task[task].invoke
    end
  end
end
