namespace :import do
  # ./bin/rake driver:hmis_external_apis:import:ac_projects
  desc 'Import AC project data'
  task :ac_projects, [] => [:environment] do
    HmisExternalApis::AcHmis::ImportProjectsJob.perform_now
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

  def reimport_mper
    # Clear MPER unit mapping / capacity data
    Hmis::Unit.destroy_all
    Hmis::Hud::CustomDataElementDefinition.find_by(key: :direct_entry)&.values&.destroy_all
    Hmis::ProjectUnitTypeMapping.destroy_all

    # Import MPER file
    # Nice to have: flag to force reimport.
    # Right now if you want to re import, you need to re upload the file (there is probably a better way but i dont know how)
    HmisExternalApis::AcHmis::ImportProjectsJob.perform_now
  end

  def reimport_everything
    Hmis::UnitOccupancy.delete_all #3621
    Hmis::ActiveRange.where(entity_type: 'Hmis::UnitOccupancy').delete_all
    Hmis::Hud::CustomService.delete_all
    Hmis::Hud::Enrollment.hmis.in_progress.each(&:really_destroy!)
    Hmis::Wip.destroy_all

    # To speed things up: delete all Client Address and Contacts using delete_all. Its really slow in the migration because it does each(&:really_destroy!)
    Hmis::Hud::CustomClientAddress.with_deleted.delete_all
    Hmis::Hud::CustomClientContactPoint.with_deleted.delete_all

    # Delete all CDEs except for Direct Entry flag
    cdeds = Hmis::Hud::CustomDataElementDefinition.where.not(key: :direct_entry).pluck(:id)
    Hmis::Hud::CustomDataElement.where(data_element_definition_id: cdeds).delete_all

    # PersonalID => MCI Uniq ID
    # (Deletes all MCI Unique IDs)
    HmisExternalApis::ExternalId.where(namespace: :ac_hmis_mci_unique_id).count # 56,371 => 58,528
    HmisExternalApis::AcHmis::Migration::InitialMciUniqueIdCreationJob.perform_now(clobber: true)

    # Import MCI Uniq => MCI
    # (Deletes all MCI IDs)
    HmisExternalApis::ExternalId.where(namespace: :ac_hmis_mci).count # 56,076 => 58,264
    HmisExternalApis::AcHmis::Migration::MciMappingImporterJob.new.best_import_file_key
    HmisExternalApis::AcHmis::Migration::MciMappingImporterJob.perform_now

    # Pull down CSV
    today = Date.current.strftime('%Y-%m-%d')
    dir = "/tmp/migration/#{today}/custom-data"
    FileUtils.mkdir_p dir
    creds = GrdaWarehouse::RemoteCredentials::S3.find_by(slug: HmisExternalApis::AcHmis::Importers::S3ZipFilesImporter::MPER_SLUG)
    s3 = creds.s3
    zipfile = "#{dir}/custom.zip"
    s3.list_objects(prefix: 'initial-migration')
    selected = s3.list_objects(prefix: 'initial-migration').filter { |o| o.key.include?('Custom') }.first.key
    selected_file_name = selected.gsub('initial-migration/', '')
    ### ALERT! Check and make sure its the right file. ###
    s3.fetch(file_name: selected_file_name, prefix: 'initial-migration', target_path: zipfile)
    system("unzip #{zipfile} -d #{dir}")

    # ls /tmp/s3-2023-08-22/custom-data
    # rm /tmp/s3-2023-08-22/custom-data/custom.zip

    # AC_HMIS_IMPORT_LOG_FILE=/tmp/gig-import.log rails driver:hmis_external_apis:import:ac_custom_data_elements[/tmp/migration/2023-08-30/custom-data,true]

    # Run custom data importers
    ENV['AC_HMIS_IMPORT_LOG_FILE'] = "/tmp/migration/#{today}-custom-migration-log.txt"
    importer = HmisExternalApis::AcHmis::Importers::CustomDataElementsImporter.new(dir: dir, clobber: true)
    importer.run!

    # Upload log file
    s3.put(file_name: ENV['AC_HMIS_IMPORT_LOG_FILE'], prefix: 'initial-migration')

    # Num referrals by type
    # {"denied_pending_status"=>1, "assigned_status"=>137, "accepted_pending_status"=>14, "accepted_status"=>877}
    HmisExternalApis::AcHmis::ReferralPosting.group(:status).count
    # The below should be 0. All Accepted/Pending should be tied to a household.
    HmisExternalApis::AcHmis::ReferralPosting.where(status: ['accepted_status', 'accepted_pending_status']).where(HouseholdID: nil).count

    # Count how many MCI and MCI Unique IDs
    HmisExternalApis::ExternalId.for_clients.group(:namespace).count
    # Num Clients wihout MCI Unique IDs
    Hmis::Hud::Client.hmis.left_outer_joins(:ac_hmis_mci_unique_id).where(ac_hmis_mci_unique_id: { id: nil }).count
    # Num Clients wihout MCI IDs
    Hmis::Hud::Client.hmis.left_outer_joins(:ac_hmis_mci_ids).where(ac_hmis_mci_ids: { id: nil }).count

    # TODO VALIDATE: how many *open* enrollment have an assigned unit?
    Hmis::Hud::Enrollment.hmis.open_on_date.joins(:current_unit).count # 3486

    # TODO: kick off MigrateAssessmentsJob
    # ADD CHECK: how many non-wip enrollments DONT HAVE intake assessments?
    # ADD CHECK: how many exited enrollments DONT HAVE exit assessments?
  end
end
