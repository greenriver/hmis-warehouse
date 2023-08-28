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
    Hmis::UnitOccupancy.delete_all
    Hmis::ActiveRange.where(entity_type: 'Hmis::UnitOccupancy').delete_all
    Hmis::Hud::CustomService.delete_all
    Hmis::Hud::Enrollment.hmis.in_progress.each(&:really_destroy!)
    Hmis::Wip.destroy_all

    # Delete all CDEs except for Direct Entry flag
    cdeds = Hmis::Hud::CustomDataElementDefinition.where.not(key: :direct_entry).pluck(:id)
    Hmis::Hud::CustomDataElement.where(data_element_definition_id: cdeds).destroy_all

    # PersonalID => MCI Uniq ID
    # (Deletes all MCI Unique IDs)
    HmisExternalApis::AcHmis::Migration::InitialMciUniqueIdCreationJob.perform_now(clobber: true)

    # Import MCI Uniq => MCI
    # (Deletes all MCI IDs)
    HmisExternalApis::AcHmis::Migration::MciMappingImporterJob.new.best_import_file_key
    HmisExternalApis::AcHmis::Migration::MciMappingImporterJob.perform_now

    # Pull down CSV
    today = Date.current.strftime('%Y-%m-%d')
    dir = "/tmp/migration/#{today}/custom-data"
    FileUtils.mkdir_p dir
    creds = GrdaWarehouse::RemoteCredentials::S3.find_by(slug: HmisExternalApis::AcHmis::Importers::S3ZipFilesImporter::MPER_SLUG)
    s3 = creds.s3
    s3.list_objects(prefix: 'initial-migration')
    zipfile = "#{dir}/custom.zip"
    s3.fetch(file_name: '2023-08-18-HMIS-Legacy-Data-csv-a28b08c4-3098-4d34-8575-d5896a018f6c-.zip', prefix: 'initial-migration', target_path: zipfile)
    system("unzip #{zipfile} -d #{dir}")

    # ls /tmp/s3-2023-08-22/custom-data
    # rm /tmp/s3-2023-08-22/custom-data/custom.zip

    # rails driver:hmis_external_apis:import:ac_custom_data_elements[/tmp/migration/2023-08-25/custom-data,true]

    # Run custom data importers
    importer = HmisExternalApis::AcHmis::Importers::CustomDataElementsImporter.new(dir: dir, clobber: true)
    importer.run!

    # Num referrals by type
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

    # TODO: kick off MigrateAssessmentsJob
  end
end
