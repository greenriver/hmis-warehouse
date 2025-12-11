###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'csv'
require 'fileutils'

# Factory for programmatically building versioned HMIS CSV fixture bundles.
# Uses HudHelper.util(version) and HmisStructure modules to generate fixtures that match HUD specifications.
#
# Supported HUD CSV versions: 2020, 2022, 2024, 2026 (default: 2026)
#
# Usage:
#   factory = HmisCsvFixtureFactory.new(version: '2026')
#   factory.export_start_date = Date.new(2024, 1, 1)
#   factory.export_end_date = Date.new(2024, 3, 31)
#   factory.add_client(personal_id: 'client-1', first_name: 'Test', last_name: 'User')
#   factory.add_enrollment(enrollment_id: 'enroll-1', personal_id: 'client-1', entry_date: Date.new(2024, 1, 15))
#   factory.add_custom_enrollment_augmentation(enrollment_id: 'enroll-1', personal_id: 'client-1', sexual_orientation: 1)
#   path = factory.create!
#   # use path with import_hmis_csv_fixture
#   factory.cleanup!
#
class HmisCsvFixtureFactory
  attr_accessor :export_id, :export_start_date, :export_end_date, :export_date
  attr_accessor :organization_id, :organization_name
  attr_accessor :project_id, :project_name, :project_type, :coc_code
  attr_reader :version

  def initialize(version: '2026')
    @version = version
    @util = HudHelper.util(version) # Access HUD utility methods (e.g., @util.project_type(1))
    @export_id = SecureRandom.hex(16)
    @export_start_date = Date.new(2024, 1, 1)
    @export_end_date = Date.new(2024, 3, 31)
    @export_date = Time.current
    @organization_id = 'org-1'
    @organization_name = 'Test Organization'
    @project_id = 'project-1'
    @project_name = 'Test Project'
    @project_type = 1 # Emergency Shelter
    @coc_code = 'XX-500'

    @clients = []
    @enrollments = []
    @custom_enrollment_augmentations = []
    @custom_gender_augmentations = []
    @tmp_dir = nil
  end

  def add_client(personal_id:, first_name: 'Test', last_name: 'Client', dob: Date.new(1990, 1, 1), **attrs)
    @clients << {
      personal_id: personal_id,
      first_name: first_name,
      last_name: last_name,
      dob: dob,
    }.merge(attrs)
  end

  def add_enrollment(enrollment_id:, personal_id:, entry_date:, project_id: nil, household_id: nil, **attrs)
    @enrollments << {
      enrollment_id: enrollment_id,
      personal_id: personal_id,
      project_id: project_id || @project_id,
      entry_date: entry_date,
      household_id: household_id || "hh-#{enrollment_id}",
    }.merge(attrs)
  end

  def add_custom_enrollment_augmentation(enrollment_id:, personal_id:, sexual_orientation: nil, translation_needed: nil, preferred_language: nil, **attrs)
    @custom_enrollment_augmentations << {
      enrollment_id: enrollment_id,
      personal_id: personal_id,
      sexual_orientation: sexual_orientation,
      translation_needed: translation_needed,
      preferred_language: preferred_language,
    }.merge(attrs)
  end

  def add_custom_gender_augmentation(personal_id:, woman: nil, man: nil, non_binary: nil, **attrs)
    @custom_gender_augmentations << {
      personal_id: personal_id,
      woman: woman,
      man: man,
      non_binary: non_binary,
    }.merge(attrs)
  end

  # Build the fixture directory and return the path (parent of 'source')
  def create!
    @tmp_dir = Dir.mktmpdir('hmis_csv_fixture')
    source_dir = File.join(@tmp_dir, 'source')
    FileUtils.mkdir_p(source_dir)

    write_export_csv(source_dir)
    write_organization_csv(source_dir)
    write_project_csv(source_dir)
    write_project_coc_csv(source_dir)
    write_user_csv(source_dir)
    write_client_csv(source_dir)
    write_enrollment_csv(source_dir)
    write_empty_files(source_dir)

    write_custom_enrollment_augmentation_csv(source_dir) if @custom_enrollment_augmentations.any?
    write_custom_gender_csv(source_dir) if @custom_gender_augmentations.any?

    @tmp_dir
  end

  def cleanup!
    FileUtils.rm_rf(@tmp_dir) if @tmp_dir && Dir.exist?(@tmp_dir)
    @tmp_dir = nil
  end

  private

  def timestamp
    @timestamp ||= Time.current.strftime('%Y-%m-%d %H:%M:%S')
  end

  # Convert snake_case to PascalCase with proper acronym handling (e.g., enrollment_id -> EnrollmentID)
  def camelize_hud_key(key)
    key.to_s.camelize.gsub(/Id$/, 'ID')
  end

  # Build a CSV row with defaults from HmisStructure configuration
  # Column order is preserved from hmis_configuration to ensure correct CSV output
  def build_row(model_class, overrides = {})
    config = model_class.hmis_configuration(version: @version)
    normalized_overrides = overrides.transform_keys(&:to_s)

    # Build row maintaining column order from config
    config.transform_keys(&:to_s).each_with_object({}) do |(key, spec), row|
      row[key] = normalized_overrides.fetch(key) { default_value_for_column(key, spec[:type]) }
    end
  end

  # Generate appropriate default values based on column name and type
  # Special handling for audit fields (DateCreated, DateUpdated) vs DateDeleted
  def default_value_for_column(column_name, type)
    case type
    when :datetime
      # Only populate audit timestamps, leave DateDeleted empty
      ['DateCreated', 'DateUpdated'].include?(column_name) ? timestamp : ''
    else
      '' # All other types default to empty string
    end
  end

  def write_export_csv(dir)
    row = build_row(GrdaWarehouse::Hud::Export, {
                      'ExportID' => @export_id,
                      'SourceType' => 3,
                      'SourceName' => 'Test Warehouse',
                      'SourceContactFirst' => 'Automated',
                      'SourceContactLast' => 'Export',
                      'ExportDate' => @export_date.strftime('%Y-%m-%d %H:%M:%S'),
                      'ExportStartDate' => @export_start_date.strftime('%Y-%m-%d'),
                      'ExportEndDate' => @export_end_date.strftime('%Y-%m-%d'),
                      'SoftwareName' => 'Test HMIS',
                      'SoftwareVersion' => '1',
                      'ExportPeriodType' => 3,
                      'ExportDirective' => 3,
                      'HashStatus' => 1,
                    })

    # Add version-specific fields
    csv_version_label = @version == '2026' ? '2026 v1.0' : @version
    row['CSVVersion'] = csv_version_label if @version.in?(['2022', '2024', '2026'])
    row['ImplementationID'] = 'Test Warehouse' if @version.in?(['2024', '2026'])

    write_csv_from_hashes(dir, 'Export.csv', [row])
  end

  def write_organization_csv(dir)
    row = build_row(GrdaWarehouse::Hud::Organization, {
                      'OrganizationID' => @organization_id,
                      'OrganizationName' => @organization_name,
                      'VictimServiceProvider' => 0,
                      'DateCreated' => timestamp,
                      'DateUpdated' => timestamp,
                      'UserID' => 'user-1',
                      'ExportID' => @export_id,
                    })
    write_csv_from_hashes(dir, 'Organization.csv', [row])
  end

  def write_project_csv(dir)
    row = build_row(GrdaWarehouse::Hud::Project, {
                      'ProjectID' => @project_id,
                      'OrganizationID' => @organization_id,
                      'ProjectName' => @project_name,
                      'OperatingStartDate' => @export_start_date.strftime('%Y-%m-%d'),
                      'ContinuumProject' => 0,
                      'ProjectType' => @project_type,
                      'TargetPopulation' => 4,
                      'DateCreated' => timestamp,
                      'DateUpdated' => timestamp,
                      'UserID' => 'user-1',
                      'ExportID' => @export_id,
                    })
    write_csv_from_hashes(dir, 'Project.csv', [row])
  end

  def write_project_coc_csv(dir)
    row = build_row(GrdaWarehouse::Hud::ProjectCoc, {
                      'ProjectCoCID' => "coc-#{@project_id}",
                      'ProjectID' => @project_id,
                      'CoCCode' => @coc_code,
                      'Geocode' => @coc_code, # Required field, use CoC code as geocode
                      'DateCreated' => timestamp,
                      'DateUpdated' => timestamp,
                      'UserID' => 'user-1',
                      'ExportID' => @export_id,
                    })
    write_csv_from_hashes(dir, 'ProjectCoC.csv', [row])
  end

  def write_user_csv(dir)
    row = build_row(GrdaWarehouse::Hud::User, {
                      'UserID' => 'user-1',
                      'UserFirstName' => 'Test',
                      'UserLastName' => 'User',
                      'UserEmail' => 'test@example.com',
                      'DateCreated' => timestamp,
                      'DateUpdated' => timestamp,
                      'ExportID' => @export_id,
                    })
    write_csv_from_hashes(dir, 'User.csv', [row])
  end

  def write_client_csv(dir)
    rows = @clients.map do |c|
      build_row(GrdaWarehouse::Hud::Client, {
        'PersonalID' => c[:personal_id],
        'FirstName' => c[:first_name],
        'LastName' => c[:last_name],
        'NameDataQuality' => 99,
        'SSNDataQuality' => 99,
        'DOB' => c[:dob].strftime('%Y-%m-%d'),
        'DOBDataQuality' => 99,
        'AmIndAKNative' => 0,
        'Asian' => 0,
        'BlackAfAmerican' => 0,
        'HispanicLatinaeo' => 0,
        'MidEastNAfrican' => 0,
        'NativeHIPacific' => 0,
        'White' => 0,
        'RaceNone' => 99,
        'VeteranStatus' => 99,
        'DateCreated' => timestamp,
        'DateUpdated' => timestamp,
        'UserID' => 'user-1',
        'ExportID' => @export_id,
      }.merge(c.except(:personal_id, :first_name, :last_name, :dob)))
    end
    write_csv_from_hashes(dir, 'Client.csv', rows)
  end

  def write_enrollment_csv(dir)
    rows = @enrollments.map do |e|
      build_row(GrdaWarehouse::Hud::Enrollment, {
        'EnrollmentID' => e[:enrollment_id],
        'PersonalID' => e[:personal_id],
        'ProjectID' => e[:project_id],
        'EntryDate' => e[:entry_date].strftime('%Y-%m-%d'),
        'HouseholdID' => e[:household_id],
        'RelationshipToHoH' => 1,
        'EnrollmentCoC' => @coc_code,
        'LivingSituation' => 116,
        'DisablingCondition' => 99,
        'DateCreated' => timestamp,
        'DateUpdated' => timestamp,
        'UserID' => 'user-1',
        'ExportID' => @export_id,
      }.merge(e.except(:enrollment_id, :personal_id, :project_id, :entry_date, :household_id)))
    end
    write_csv_from_hashes(dir, 'Enrollment.csv', rows)
  end

  def write_custom_enrollment_augmentation_csv(dir)
    rows = @custom_enrollment_augmentations.map do |attrs|
      build_row(HmisCsvTwentyTwentySix::Importer::Custom::CustomEnrollmentFy26Deprecation, {
        'DateCreated' => timestamp,
        'DateUpdated' => timestamp,
        'UserID' => 'user-1',
        'ExportID' => @export_id,
      }.merge(attrs.transform_keys { |k| camelize_hud_key(k) }))
    end
    write_csv_from_hashes(dir, 'CustomEnrollmentFY26Deprecations.csv', rows)
  end

  def write_custom_gender_csv(dir)
    rows = @custom_gender_augmentations.map do |attrs|
      build_row(HmisCsvTwentyTwentySix::Importer::Custom::CustomGender, {
        'DateCreated' => timestamp,
        'DateUpdated' => timestamp,
        'UserID' => 'user-1',
        'ExportID' => @export_id,
      }.merge(attrs.transform_keys { |k| camelize_hud_key(k) }))
    end
    write_csv_from_hashes(dir, 'CustomGender.csv', rows)
  end

  # Write empty placeholder files for required HUD tables we don't populate
  def write_empty_files(dir)
    empty_models = {
      'Affiliation.csv' => GrdaWarehouse::Hud::Affiliation,
      'Assessment.csv' => GrdaWarehouse::Hud::Assessment,
      'AssessmentQuestions.csv' => GrdaWarehouse::Hud::AssessmentQuestion,
      'AssessmentResults.csv' => GrdaWarehouse::Hud::AssessmentResult,
      'CEParticipation.csv' => GrdaWarehouse::Hud::CeParticipation,
      'CurrentLivingSituation.csv' => GrdaWarehouse::Hud::CurrentLivingSituation,
      'EmploymentEducation.csv' => GrdaWarehouse::Hud::EmploymentEducation,
      'Event.csv' => GrdaWarehouse::Hud::Event,
      'Exit.csv' => GrdaWarehouse::Hud::Exit,
      'Funder.csv' => GrdaWarehouse::Hud::Funder,
      'HMISParticipation.csv' => GrdaWarehouse::Hud::HmisParticipation,
      'Inventory.csv' => GrdaWarehouse::Hud::Inventory,
      'Services.csv' => GrdaWarehouse::Hud::Service,
      'YouthEducationStatus.csv' => GrdaWarehouse::Hud::YouthEducationStatus,
    }

    empty_models.each do |filename, model_class|
      headers = model_class.hmis_configuration(version: @version).keys.map(&:to_s)
      write_csv(dir, filename, headers, [])
    end
  end

  def write_csv_from_hashes(dir, filename, rows_of_hashes)
    return if rows_of_hashes.empty?

    path = File.join(dir, filename)
    headers = rows_of_hashes.first.keys

    CSV.open(path, 'wb') do |csv|
      csv << headers
      rows_of_hashes.each do |row|
        csv << row.values_at(*headers)
      end
    end
  end

  def write_csv(dir, filename, headers, rows)
    path = File.join(dir, filename)
    CSV.open(path, 'wb') do |csv|
      csv << headers
      rows.each { |row| csv << row }
    end
  end
end
