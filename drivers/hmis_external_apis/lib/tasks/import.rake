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

  # Usage: rails driver:hmis_external_apis:import:ac_import_move_in_addresses_20231128[var/SampleMoveInAddr.csv,true]
  desc 'One-off import Move-in Addresses'
  task :ac_import_move_in_addresses_20231128, [:file, :dry_run] => [:environment] do |_task, args|
    raise 'file not valid' unless args.file && File.exist?(args.file)

    dry_run = args.dry_run == 'true'

    Rails.logger.info "Dry run? #{dry_run}"

    require 'csv'

    csv = CSV.read(args.file, headers: true)

    data_source = GrdaWarehouse::DataSource.hmis.first
    system_hud_user = Hmis::Hud::User.system_user(data_source_id: data_source.id)
    enrollments_with_move_in_addresses = Hmis::Hud::CustomClientAddress.move_in.pluck(:enrollment_id).to_set
    skipped = 0
    records = []
    seen = []
    csv.each do |row|
      enrollment_id = row['ENROLLMENTID']
      project_id = row['LEGACY_PROJECTID']
      personal_id = row['LEGACY_PERSONALID']
      warehouse_id = row['WAREHOUSE_PERSONAL_ID']

      client = Hmis::Hud::Client.hmis.find_by(personal_id: personal_id)
      if client.nil?
        # If we can't find by personal ID, try to look up by warehouse ID. Only needed for a couple that have been merged.
        id = GrdaWarehouse::Hud::Client.find(warehouse_id).source_clients.find_by(data_source_id: data_source.id)&.id
        client = Hmis::Hud::Client.find_by(id: id) if id
      end
      unless client
        Rails.logger.info "client not found: #{personal_id}"
        skipped += 1
        next
      end

      enrollment = client.enrollments.find_by(enrollment_id: enrollment_id, project_id: project_id)
      unless enrollment
        Rails.logger.info "enrollment not found: #{enrollment_id} (#{row['LEGACY_PROJECT_NAME']})"
        skipped += 1
        next
      end

      if enrollments_with_move_in_addresses.include?(enrollment.enrollment_id)
        Rails.logger.info "enrollment already has a move in address: #{enrollment_id} (#{row['LEGACY_PROJECT_NAME']})"
        skipped += 1
        next
      end

      if seen.include?(enrollment.enrollment_id)
        Rails.logger.info "file contains multiple move-in addresses for #{enrollment.enrollment_id}, skipping. (#{row['LEGACY_PROJECT_NAME']})"
        skipped += 1
        next
      end

      seen << enrollment.enrollment_id

      records << Hmis::Hud::CustomClientAddress.new(
        AddressID: Hmis::Hud::Base.generate_uuid,
        enrollment_address_type: :move_in,
        data_source_id: enrollment.data_source_id,
        EnrollmentID: enrollment.EnrollmentID,
        PersonalID: enrollment.PersonalID,
        UserID: system_hud_user.UserID,
        line1: row['ADDRESS_LINE_1'],
        line2: row['ADDRESS_LINE_2'],
        city: row['CITY'],
        state: row['STATE'],
        postal_code: row['ZIP_CD'],
      )
    end

    Rails.logger.info "Skipped #{skipped}. #{records.size} to create."
    Rails.logger.info "Dry run? #{dry_run}"
    next if dry_run

    Rails.logger.info 'Importing records'
    Hmis::Hud::CustomClientAddress.transaction do
      result = Hmis::Hud::CustomClientAddress.import(records)
      raise "Failed to import #{result.failed_instances} records" if result.failed_instances.present?
    end
  end
end
