# frozen_string_literal: true

class CreateFy2026LoadingAndImportTables < ActiveRecord::Migration[7.1]
  def up
    StrongMigrations.disable_check(:add_index) # Indexes are created inside hmis_table_create_indices!, so don't complain about them

    spec_version = '2026'

    # Loader tables
    HmisCsvTwentyTwentySix.loadable_files.each_value do |klass|
      klass.hmis_table_create!(version: spec_version, constraints: false, types: false)
      klass.hmis_table_create_indices!(version: spec_version, ignored_indexes: ignored_loader_indexes)
    end

    HmisCsvTwentyTwentySix.loadable_files.each_value do |klass|
      column_names = klass.column_names
      add_reference klass.table_name, :data_source, null: false, index: false
      add_column klass.table_name, :loaded_at, :datetime, null: false
      add_reference klass.table_name, :loader, null: false, index: false

      add_index klass.table_name, :data_source_id
      add_index klass.table_name, :loader_id
      add_index klass.table_name, [klass.hud_key, :data_source_id], name: "#{klass.table_name}-#{Digest::MD5.hexdigest([klass.hud_key, :data_source_id].join('_'))[0, 4]}"
      if column_names.include?('EnrollmentID') && ! klass.hud_key == :EnrollmentID
        next if ignored_loader_indexes[['EnrollmentID', 'data_source_id']]&.include?(klass.table_name)

        add_index klass.table_name, [:EnrollmentID, :data_source_id], name: "#{klass.table_name}-#{Digest::MD5.hexdigest([:EnrollmentID, :data_source_id].join('_'))[0, 4]}"
      end
      next unless column_names.include?('ProjectID') && ! klass.hud_key == :ProjectID
      next if ignored_loader_indexes[['ProjectID', 'data_source_id']]&.include?(klass.table_name)

      add_index klass.table_name, [:ProjectID, :data_source_id], name: "#{klass.table_name}-#{Digest::MD5.hexdigest([:ProjectID, :data_source_id].join('_'))[0, 4]}"
    end

    # Importer tables
    HmisCsvTwentyTwentySix.importable_files.each_value do |klass|
      klass.hmis_table_create!(version: spec_version, constraints: false)
      klass.hmis_table_create_indices!(version: spec_version)
    end

    HmisCsvTwentyTwentySix.importable_files.each_value do |klass|
      column_names = klass.column_names
      add_reference klass.table_name, :data_source, null: false, index: false
      add_reference klass.table_name, :importer_log, null: false, index: false
      add_column klass.table_name, :pre_processed_at, :datetime, null: false
      add_column klass.table_name, :source_hash, :string
      add_reference klass.table_name, :source, null: false, index: false
      add_column klass.table_name, :source_type, :string, null: false

      add_column klass.table_name, :dirty_at, :timestamp
      add_column klass.table_name, :clean_at, :timestamp

      add_column klass.table_name, :should_import, :boolean, default: true

      add_index klass.table_name, :data_source_id
      add_index klass.table_name, :importer_log_id
      # Always index on primary key data_source_id combination
      add_index klass.table_name, [klass.hud_key, :data_source_id], name: "#{klass.table_name}-#{Digest::MD5.hexdigest([klass.hud_key, :data_source_id].join('_'))[0, 4]}"

      add_index klass.table_name, [:source_type, :source_id], name: klass.table_name + '-' + Digest::MD5.hexdigest([:source_type, :source_id].join('_'))[0, 4] unless ignored_importer_indexes[['source_type', 'source_id']]&.include?(klass.table_name)

      if column_names.include?('EnrollmentID') && ! klass.hud_key == :EnrollmentID
        add_index klass.table_name, [:EnrollmentID, :data_source_id], name: "#{klass.table_name}-#{Digest::MD5.hexdigest([:EnrollmentID, :data_source_id].join('_'))[0, 4]}" unless ignored_importer_indexes[['EnrollmentID', 'data_source_id']]&.include?(klass.table_name)
      end
      next unless column_names.include?('ProjectID') && ! klass.hud_key == :ProjectID

      add_index klass.table_name, [:ProjectID, :data_source_id], name: "#{klass.table_name}-#{Digest::MD5.hexdigest([:ProjectID, :data_source_id].join('_'))[0, 4]}" unless ignored_importer_indexes[['ProjectID', 'data_source_id']]&.include?(klass.table_name)
    end
  end

  def ignored_importer_indexes
    @ignored_importer_indexes ||= {
      ['source_type', 'source_id'] => [
        'hmis_2026_affiliations',
        'hmis_2026_assessment_questions',
        'hmis_2026_assessment_results',
        'hmis_2026_assessments',
        'hmis_2026_ce_participations',
        'hmis_2026_clients',
        'hmis_2026_current_living_situations',
        'hmis_2026_disabilities',
        'hmis_2026_employment_educations',
        'hmis_2026_enrollments',
        'hmis_2026_events',
        'hmis_2026_exits',
        'hmis_2026_exports',
        'hmis_2026_funders',
        'hmis_2026_health_and_dvs',
        'hmis_2026_hmis_participations',
        'hmis_2026_income_benefits',
        'hmis_2026_inventories',
        'hmis_2026_organizations',
        'hmis_2026_project_cocs',
        'hmis_2026_projects',
        'hmis_2026_services',
        'hmis_2026_users',
        'hmis_2026_youth_education_statuses',
      ],
      ['EnrollmentID'] => [
        'hmis_2026_assessments',
        'hmis_2026_disabilities',
        'hmis_2026_employment_educations',
        'hmis_2026_events',
        'hmis_2026_health_and_dvs',
        'hmis_2026_income_benefits',
        'hmis_2026_youth_education_statuses',
      ],
      ['PersonalID'] => [
        'hmis_2026_assessments',
        'hmis_2026_current_living_situations',
        'hmis_2026_employment_educations',
        'hmis_2026_events',
        'hmis_2026_health_and_dvs',
        'hmis_2026_income_benefits',
        'hmis_2026_services',
        'hmis_2026_youth_education_statuses',
      ],
      ['DateCreated'] => [
        'hmis_2026_clients',
        'hmis_2026_employment_educations',
        'hmis_2026_enrollments',
        'hmis_2026_exits',
        'hmis_2026_health_and_dvs',
        'hmis_2026_income_benefits',
        'hmis_2026_project_cocs',
        'hmis_2026_projects',
        'hmis_2026_services',
      ],
      ['ProjectID', 'CoCCode'] => [
        'hmis_2026_inventories',
        'hmis_2026_project_cocs',
      ],
      ['RecordType', 'DateProvided'] => [
        'hmis_2026_services',
      ],
      ['PersonalID', 'RecordType', 'EnrollmentID', 'DateProvided'] => [
        'hmis_2026_services',
      ],
      ['EnrollmentID', 'RecordType', 'DateDeleted', 'DateProvided'] => [
        'hmis_2026_services',
      ],
      ['RecordType', 'DateDeleted', 'DateProvided'] => [
        'hmis_2026_services',
      ],
      ['EnrollmentID', 'PersonalID'] => [
        'hmis_2026_services',
      ],
      ['RecordType', 'DateDeleted'] => [
        'hmis_2026_services',
      ],
      ['DOB'] => [
        'hmis_2026_clients',
      ],
      ['FirstName'] => [
        'hmis_2026_clients',
      ],
      ['LastName'] => [
        'hmis_2026_clients',
      ],
      ['AssessmentID'] => [
        'hmis_2026_assessment_results',
      ],
      ['ExportID'] => [
        'hmis_2026_exports',
        'hmis_2026_projects',
      ],
      ['ExitDate', 'Destination'] => [
        'hmis_2026_exits',
      ],
      ['DateDeleted'] => [
        'hmis_2026_exits',
      ],
      ['MonthsHomelessPastThreeYears'] => [
        'hmis_2026_enrollments',
      ],
      ['LengthOfStay'] => [
        'hmis_2026_enrollments',
      ],
      ['HouseholdID', 'DateDeleted', 'EntryDate', 'RelationshipToHoH'] => [
        'hmis_2026_enrollments',
      ],
      ['EntryDate'] => [
        'hmis_2026_enrollments',
      ],
      ['LivingSituation'] => [
        'hmis_2026_enrollments',
      ],
      ['HouseholdID', 'DateDeleted', 'RelationshipToHoH'] => [
        'hmis_2026_enrollments',
      ],
      ['DateDeleted', 'RelationshipToHoH'] => [
        'hmis_2026_enrollments',
      ],
      ['TimesHomelessPastThreeYears', 'MonthsHomelessPastThreeYears'] => [
        'hmis_2026_enrollments',
      ],
      ['RelationshipToHoH', 'DateDeleted'] => [
        'hmis_2026_enrollments',
      ],
      ['DateDeleted', 'EntryDate'] => [
        'hmis_2026_enrollments',
      ],
      ['MoveInDate'] => [
        'hmis_2026_enrollments',
      ],
    }
  end

  def ignored_loader_indexes
    @ignored_loader_indexes ||= {
      ['PersonalID'] => [
        'hmis_csv_2026_assessments',
        'hmis_csv_2026_current_living_situations',
        'hmis_csv_2026_employment_educations',
        'hmis_csv_2026_events',
        'hmis_csv_2026_enrollments',
        'hmis_csv_2026_exits',
        'hmis_csv_2026_health_and_dvs',
        'hmis_csv_2026_income_benefits',
        'hmis_csv_2026_services',
        'hmis_csv_2026_youth_education_statuses',
      ],
      ['EnrollmentID'] => [
        'hmis_csv_2026_assessments',
        'hmis_csv_2026_current_living_situations',
        'hmis_csv_2026_employment_educations',
        'hmis_csv_2026_health_and_dvs',
        'hmis_csv_2026_income_benefits',
        'hmis_csv_2026_services',
        'hmis_csv_2026_youth_education_statuses',
      ],
      ['ExportID'] => [
        'hmis_csv_2026_affiliations',
        'hmis_csv_2026_organizations',
        'hmis_csv_2026_projects',
      ],
      ['DateCreated'] => [
        'hmis_csv_2026_clients',
        'hmis_csv_2026_disabilities',
        'hmis_csv_2026_employment_educations',
        'hmis_csv_2026_enrollments',
        'hmis_csv_2026_exits',
        'hmis_csv_2026_funders',
        'hmis_csv_2026_health_and_dvs',
        'hmis_csv_2026_income_benefits',
        'hmis_csv_2026_inventories',
        'hmis_csv_2026_project_cocs',
        'hmis_csv_2026_projects',
        'hmis_csv_2026_services',
      ],
      ['DateUpdated'] => [
        'hmis_csv_2026_clients',
        'hmis_csv_2026_disabilities',
        'hmis_csv_2026_employment_educations',
        'hmis_csv_2026_enrollments',
        'hmis_csv_2026_exits',
        'hmis_csv_2026_funders',
        'hmis_csv_2026_health_and_dvs',
        'hmis_csv_2026_income_benefits',
        'hmis_csv_2026_inventories',
        'hmis_csv_2026_project_cocs',
        'hmis_csv_2026_projects',
        'hmis_csv_2026_services',
      ],
      ['ProjectID', 'CoCCode'] => [
        'hmis_csv_2026_inventories',
        'hmis_csv_2026_project_cocs',
      ],
      ['DateDeleted', 'RelationshipToHoH'] => [
        'hmis_csv_2026_enrollments',
      ],
      ['DateDeleted', 'EntryDate'] => [
        'hmis_csv_2026_enrollments',
      ],
      ['ProjectID', 'HouseholdID'] => [
        'hmis_csv_2026_enrollments',
      ],
      ['HouseholdID'] => [
        'hmis_csv_2026_enrollments',
      ],
      ['HouseholdID', 'DateDeleted', 'EntryDate', 'RelationshipToHoH'] => [
        'hmis_csv_2026_enrollments',
      ],
      ['HouseholdID', 'DateDeleted', 'RelationshipToHoH'] => [
        'hmis_csv_2026_enrollments',
      ],
      ['HouseholdID', 'RelationshipToHoH', 'DateDeleted'] => [
        'hmis_csv_2026_enrollments',
      ],
      ['EntryDate'] => [
        'hmis_csv_2026_enrollments',
      ],
      ['LivingSituation'] => [
        'hmis_csv_2026_enrollments',
      ],
      ['LengthOfStay'] => [
        'hmis_csv_2026_enrollments',
      ],
      ['MonthsHomelessPastThreeYears'] => [
        'hmis_csv_2026_enrollments',
      ],
      ['MoveInDate'] => [
        'hmis_csv_2026_enrollments',
      ],
      ['TimesHomelessPastThreeYears', 'MonthsHomelessPastThreeYears'] => [
        'hmis_csv_2026_enrollments',
      ],
      ['EnrollmentID', 'PersonalID'] => [
        'hmis_csv_2026_enrollments',
        'hmis_csv_2026_services',
      ],
      ['ProjectID'] => [
        'hmis_csv_2026_enrollments',
      ],
      ['RelationshipToHoH'] => [
        'hmis_csv_2026_enrollments',
      ],
      ['RelationshipToHoH', 'DateDeleted'] => [
        'hmis_csv_2026_enrollments',
      ],
      ['ProjectID', 'RelationshipToHoH'] => [
        'hmis_csv_2026_enrollments',
      ],
      ['ProjectID', 'RelationshipToHoH', 'DateDeleted'] => [
        'hmis_csv_2026_enrollments',
      ],
      ['ProjectType'] => [
        'hmis_csv_2026_projects',
      ],
      ['RecordType', 'DateProvided'] => [
        'hmis_csv_2026_services',
      ],
      ['PersonalID', 'RecordType', 'EnrollmentID', 'DateProvided'] => [
        'hmis_csv_2026_services',
      ],
      ['EnrollmentID', 'RecordType', 'DateDeleted', 'DateProvided'] => [
        'hmis_csv_2026_services',
      ],
      ['RecordType', 'DateDeleted', 'DateProvided'] => [
        'hmis_csv_2026_services',
      ],
      ['EnrollmentID', 'RecordType', 'DateDeleted'] => [
        'hmis_csv_2026_services',
      ],
      ['RecordType', 'DateDeleted'] => [
        'hmis_csv_2026_services',
      ],
      ['ExitDate', 'Destination'] => [
        'hmis_csv_2026_exits',
      ],
      ['DateDeleted'] => [
        'hmis_csv_2026_exits',
      ],
      ['InformationDate'] => [
        'hmis_csv_2026_current_living_situations',
        'hmis_csv_2026_income_benefits',
      ],
      ['DOB'] => [
        'hmis_csv_2026_clients',
      ],
      ['FirstName'] => [
        'hmis_csv_2026_clients',
      ],
      ['LastName'] => [
        'hmis_csv_2026_clients',
      ],
      ['AssessmentID'] => [
        'hmis_csv_2026_assessment_results',
      ],
      ['HMISParticipationID'] => [
        'hmis_csv_2026_hmis_participations',
      ],
    }
  end

  def down
    HmisCsvTwentyTwentySix.loadable_files.each_value do |klass|
      drop_table klass.table_name
    end

    HmisCsvTwentyTwentySix.importable_files.each_value do |klass|
      drop_table klass.table_name
    end
  end
end
