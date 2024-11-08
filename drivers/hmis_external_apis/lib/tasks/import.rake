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

  # Usage: rails driver:hmis_external_apis:import:ac_import_project_20241108[var/hssc,true,1400]
  desc 'One-off import AC project data'
  task :ac_import_project_20241108, [:dir, :dry_run, :project_id] => [:environment] do |_task, args|
    raise 'dir not valid' unless args.dir && File.directory?(args.dir)
    raise 'dry_run not valid' unless args.dry_run.in?(['true', 'false'])
    raise 'project_id not valid' unless Hmis::Hud::Project.hmis.find_by(id: args.project_id)

    dry_run = args.dry_run == 'true'
    dir = args.dir
    project_id = args.project_id

    Rails.logger.info "Dry run? #{dry_run}"

    # Custom Mappings
    relation_to_id_mapping = {
      0 => 99, # NULL
      1 => 4, # Parent
      2 => 4, # Brother
      3 => 4, # Sister
      4 => 2, # Son
      5 => 2, # Daughter
      6 => 1, # Self
      7 => 3, # Spouse/Partner
      8 => 4, # Grandparent
      9 => 4, # Grandchild
      10 => 4, # Aunt
      11 => 4, # Uncle
      12 => 4, # Niece
      13 => 4, # Nephew
      14 => 4, # Cousin
      15 => 5, # Friend
      16 => 5, # Live-In Aide
    }
    contact_type_mapping = {
      14 => 'Face-to-Face',
      15 => 'Incoming Phone',
      16 => 'Incoming Email/Text',
      17 => 'Outgoing Phone',
      18 => 'Outgoing Email/Text',
      19 => 'Meeting',
      20 => 'Community',
      21 => 'Court',
      22 => 'Family/Youths home',
      23 => 'Office',
      24 => 'School',
      25 => 'Shelter',
      26 => 'Hotel',
    }

    data_source = GrdaWarehouse::DataSource.hmis.first
    system_hud_user = Hmis::Hud::User.system_user(data_source_id: data_source.id)
    project = Hmis::Hud::Project.hmis.find(project_id)

    # Read Export file. Each row is a "Case" which represents a HoH Enrollment. It gives us the Entry Date.
    export_file = HmisExternalApis::TcHmis::Importers::Loaders::XlsxFile.new(filename: "#{dir}/HCM-EXPORT.xlsx", sheet_number: 0, header_row_number: 1)

    skipped_case_ids = []
    referral_id_to_case_id = {}
    referral_id_to_entry_date = {}
    export_file.each do |row|
      referral_id = row.field_value('ReferralID')
      case_id = row.field_value('CASE_ID')
      entry_date_time = row.field_value('OPEN_DT')
      # Skip if any required fields are missing
      unless case_id && referral_id && entry_date_time
        skipped_case_ids << case_id
        next
      end
      # Skip if Referral ID already processed (shouldn't happen)
      if referral_id_to_case_id.key?(referral_id)
        Rails.logger.info "Referral ID #{referral_id} already seen. Skipping."
        next
      end

      referral_id_to_case_id[referral_id] = case_id
      referral_id_to_entry_date[referral_id] = entry_date_time
    end

    # Read Household file. Each row is a household member. They are linked together by HOUSEHOLD_ID.
    # Later on, we will create an Enrollment for each household member. For now, just store the mappings. The ReferralID is used to cross reference with the main Export file.
    hh_export_file = HmisExternalApis::TcHmis::Importers::Loaders::XlsxFile.new(filename: "#{dir}/HCM-EXPORT-HH.xlsx", sheet_number: 0, header_row_number: 1)
    referral_id_to_hh_id = {} # just to check for duplicates
    referral_id_to_household = {}
    mci_ids = Set.new
    hh_export_file.each do |row|
      referral_id = row.field_value('ReferralID')
      household_id = row.field_value('HOUSEHOLD_ID')
      mci_id = row.field_value('MCI_ID')
      mci_ids << mci_id
      relation_to_id = row.field_value('RELATION_TO_ID')

      unless household_id && referral_id && mci_id
        skipped_case_ids << case_id
        next
      end

      # Raise if Referral ID has multiple households, shouldn't happen
      raise "Referral ID #{referral_id} linked to multiple households. unexpected." if referral_id_to_hh_id.key?(referral_id) && referral_id_to_hh_id[referral_id] != household_id

      referral_id_to_hh_id[referral_id] = household_id

      referral_id_to_household[referral_id] ||= []
      referral_id_to_household[referral_id] << { mci_id: mci_id, relation_to_id: relation_to_id }
    end

    # Find Clients. No special care taken to situation where there are multiple clients with the same MCI ID, just pick one.
    mci_id_to_client = HmisExternalApis::ExternalId.mci_ids.
      where(value: mci_ids).
      order(:id).
      preload(:source).index_by(&:value)

    # Build Enrollments
    enrollments = []
    # Map { Case ID => Enrollment }, so we can match to Case Notes file later. Maps to HoH or just some member if there is no HoH.
    case_id_to_hoh_enrollment = {}
    # MCI IDs that were skipped because we couldn't find them in our system.
    skipped_mci_ids = []

    referral_id_to_entry_date.each do |referral_id, entry_date_time|
      case_id = referral_id_to_case_id[referral_id]

      household = referral_id_to_household[referral_id]
      if !household
        Rails.logger.info "Household not found for referral ID #{referral_id}. Skipping."
        skipped_case_ids << case_id
        next
      end

      household_id = Hmis::Hud::Base.generate_uuid
      household.each do |member|
        client = mci_id_to_client[member[:mci_id].to_s]&.source
        if !client
          skipped_mci_ids << member[:mci_id]
          next # Skip but proceed with other members in the household
        end

        relationship_to_hoh = relation_to_id_mapping[member[:relation_to_id]] || 99
        enrollment_id = Hmis::Hud::Base.generate_uuid
        enrollment = Hmis::Hud::Enrollment.new(
          ProjectID: project.ProjectID,
          project_pk: project.id,
          client: client,
          EnrollmentID: enrollment_id,
          EntryDate: entry_date_time.to_date,
          RelationshipToHoH: relationship_to_hoh,
          HouseholdID: household_id,
          DateCreated: entry_date_time,
          DateUpdated: entry_date_time,
          UserID: system_hud_user.user_id,
        )

        case_id_to_hoh_enrollment[case_id] ||= enrollment
        case_id_to_hoh_enrollment[case_id] = enrollment if enrollment.head_of_household?

        enrollments << enrollment
      end

      # If couldn't find ANY household members for this household, log the CASE_ID as skipped
      skipped_case_ids << case_id unless case_id_to_hoh_enrollment[case_id]
    end

    # Build CaseNotes
    case_notes_export_file = HmisExternalApis::TcHmis::Importers::Loaders::XlsxFile.new(filename: "#{dir}/HCM-EXPORT-ContactNotes.xlsx", sheet_number: 0, header_row_number: 1)

    case_notes = []
    skipped_case_notes_ids = []
    case_notes_export_file.each do |row|
      case_id = row.field_value('CASEID')
      information_date = row.field_value('CONTACT_DT')
      note_content = row.field_value('CONTACT_NOTES')
      contact_type = row.field_value('CONTACT_TYP_ID') # Append to note instead of storing in CDED, for simplicity
      contact_type_str = contact_type_mapping[contact_type]
      note_content << "\nContact Type: #{contact_type_str}" if contact_type_str
      date_created = row.field_value('CREATED_DT')
      date_updated = row.field_value('LST_UPDT_DT')
      user_id = row.field_value('LST_UPDT_ID')

      enrollment = case_id_to_hoh_enrollment[case_id]
      if !enrollment
        skipped_case_notes_ids << row.field_value('CONTACT_ID') # Enrollment not found, skip and record
        next
      end
      case_notes << Hmis::Hud::CustomCaseNote.new(
        CustomCaseNoteID: Hmis::Hud::Base.generate_uuid,
        EnrollmentID: enrollment.EnrollmentID,
        PersonalID: enrollment.PersonalID,
        data_source_id: enrollment.data_source_id,
        content: note_content,
        UserID: user_id,
        DateCreated: date_created,
        DateUpdated: date_updated,
        information_date: information_date.to_date,
      )
    end

    Rails.logger.info "Skipped Case IDs: #{skipped_case_ids}"
    Rails.logger.info "Skipped MCI IDs: #{skipped_mci_ids}"
    Rails.logger.info "Skipped Case Notes Case IDs: #{skipped_case_notes_ids}"
    Rails.logger.info "Built #{enrollments.count} Enrollments and #{case_notes.count} Case Notes for Project #{project.ProjectName}"
    next if dry_run

    # Import Enrollment and Case Note records
    Rails.logger.info 'Importing records'
    Hmis::Hud::Base.transaction do
      result = Hmis::Hud::Enrollment.import(enrollments)
      raise "Failed to import #{result.failed_instances} Enrollments" if result.failed_instances.present?

      result = Hmis::Hud::CustomCaseNote.import(case_notes)
      raise "Failed to import #{result.failed_instances} CustomCaseNotes" if result.failed_instances.present?
    end

    # Generate Intake Assessments for the new Enrollments
    Rails.logger.info 'Generating intake assessments'
    Hmis::MigrateAssessmentsJob.perform_now(
      data_source_id: data_source.id,
      project_ids: [project.id], # run for whole project because it had no enrollments before
      generate_empty_intakes: true,
    )
  end
end
