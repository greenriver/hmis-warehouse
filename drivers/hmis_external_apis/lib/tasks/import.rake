namespace :import do
  # ./bin/rake driver:hmis_external_apis:import:ac_projects
  desc 'Import AC project data'
  task :ac_projects, [] => [:environment] do
    HmisExternalApis::AcHmis::ImportProjectsJob.perform_now
  end

  # ./bin/rake driver:hmis_external_apis:import:ac_clients_with_active_referrals
  desc 'Fetch MCI IDs of Clients with active referrals in LINK'
  task :ac_clients_with_active_referrals, [] => [:environment] do
    HmisExternalApis::AcHmis::FetchClientsWithActiveReferralsJob.perform_now
  end

  # ./bin/rake driver:hmis_external_apis:import:ac_warehouse_changes
  desc 'Fetch changes to MCI Unique IDs from AC Data Warehouse'
  task :ac_warehouse_changes, [] => [:environment] do
    HmisExternalApis::AcHmis::WarehouseChangesJob.perform_now(actor_id: User.system_user.id)
  end

  # Usage: rails driver:hmis_external_apis:import:ac_custom_data_elements[/tmp/dir,true]
  #   * dir: directory containing CSV files to import. Consult the loader classes for expected
  #     CSV filenames
  #   * clobber: should the importer destroy all existing records before importing? If clobber
  #     is false, the importer attempts to update or upsert records.
  #   * NOTE: only the referral posting and referral request loaders support upsert.
  desc 'Import AC Custom Data Elements, "dir"'
  task :ac_custom_data_elements, [:dir, :clobber] => [:environment] do |_task, args|
    raise 'dir not valid' unless args.dir && File.directory?(args.dir)
    raise clobber no valid unless args.clobber.in?(['true', 'false'])

    importer = HmisExternalApis::AcHmis::Importers::CustomDataElementsImporter.new(dir: args.dir, clobber: args.clobber == 'true')
    importer.run!
  end
end
