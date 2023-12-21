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

  # Usage: rails driver:hmis_external_apis:import:ac_import_move_in_addresses_20231128[var/SampleMoveInAddr.csv,true]
  desc 'One-off import Services Provided'
  task :sh_import_services_provided_20231019, [:file, :dry_run] => [:environment] do |_task, args|
    raise 'file not valid' unless args.file && File.exist?(args.file)

    dry_run = args.dry_run == 'true'

    Rails.logger.info "Dry run? #{dry_run}"

    require 'csv'

    csv = CSV.read(args.file, headers: true)

    data_source = GrdaWarehouse::DataSource.hmis.first
    system_hud_user = Hmis::Hud::User.system_user(data_source_id: data_source.id)
    skipped = 0
    expected = 0
    records = []

    # { Unique ID => CustomCaseNote record }
    records_by_id = {}
    enrollment_id_to_personal_id = Hmis::Hud::Enrollment.hmis.pluck(:enrollment_id, :personal_id).to_h

    DATE_TIME_FMT = '%Y/%m/%d %H:%M:%S'.freeze

    def parse_date(str)
      return unless str

      DateTime.strptime(str, DATE_TIME_FMT)
    end
    hud_user_ids = Hmis::Hud::User.hmis.pluck(:user_id).to_set
    csv.each do |row|
      personal_id = row['Participant Enterprise Identifier']&.gsub(/-/, '')
      enrollment_id = row['Unique Enrollment Identifier'].gsub(/{|}|-/, '')
      unique_note_id = row['Question Unique Identifier']
      next unless enrollment_id
      next unless personal_id

      expected += 1 unless records_by_id.key?(unique_note_id)

      # its ok if the personal id doesnt match because they may have been merged. go off enrollment id only.
      real_personal_id = enrollment_id_to_personal_id[enrollment_id]
      # enrollment ID not found, skip
      next unless real_personal_id

      date_taken = parse_date(row['Date Taken'])&.to_date
      date_last_updated = parse_date(row['Date Last Updated'])
      staff_id = row['Staff ID']
      user_id = hud_user_ids.include?(staff_id) ? staff_id : system_hud_user.user_id
      records_by_id[unique_note_id] ||= {
        EnrollmentID: enrollment_id,
        PersonalID: real_personal_id,
        CustomServiceID: Hmis::Hud::Base.generate_uuid,
        data_source_id: data_source.id,
        information_date: date_taken,
        UserID: user_id,
        DateCreated: date_taken,
        DateUpdated: date_last_updated,
      }

      records_by_id[unique_note_id][:DateCreated] = [records_by_id[unique_note_id][:DateCreated], date_taken].min
      records_by_id[unique_note_id][:DateUpdated] = [records_by_id[unique_note_id][:DateUpdated], date_last_updated].max

      question = row['Question']
      next unless row['Answer']&.present?

      case question
      when 'Date of Contact'
        info_date = parse_date(row['Answer'])&.to_date
        records_by_id[unique_note_id][:information_date] = info_date if info_date
      when 'Contact Location / Method'
        records_by_id[unique_note_id][:location] = "Location: #{row['Answer']}"
      when 'Date of Next Contact'
        records_by_id[unique_note_id][:next_contact] = "Date of Next Contact: #{row['Answer']}" # format
      when 'HUD Services Provided'
        services = row['Answer']&.split('|')&.compact_blank&.join(', ')
        records_by_id[unique_note_id][:services_provided] = "Services Provided: #{services}"
      when 'Time Spent'
        records_by_id[unique_note_id][:time_spent] = "Time Spent: #{row['Answer']}"
      when 'Notes'
        records_by_id[unique_note_id][:notes] = "Notes: #{row['Answer']}"
      end
    end

    records = []
    records_by_id.each do |id, hash|
      note_keyset = [:location, :next_contact, :services_provided, :time_spent, :notes]
      left, right = hash.partition { |k, _v| note_keyset.include?(k) }.map(&:to_h)

      right.compact_blank!
      content = []
      content << right[:services_provided]
      content << right[:notes]
      content << right[:location]
      content << right[:time_spent]
      content << right[:next_contact]
      left[:content] = content.join("\n\n")
      records << left
    end

    Rails.logger.info "Skipped #{skipped}. #{records.size} to create."
    Rails.logger.info "Dry run? #{dry_run}"
    next if dry_run

    Rails.logger.info 'Importing records'
    # Hmis::Hud::CustomCaseNote.transaction do
    #   result = Hmis::Hud::CustomCaseNote.import(records)
    #   raise "Failed to import #{result.failed_instances} records" if result.failed_instances.any?
    # end
  end
end
