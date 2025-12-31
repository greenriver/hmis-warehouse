# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require_relative './table_comparisons'

RSpec.shared_context 'datalab testkit context', shared_context: :metadata do
  include DatalabTestkit::TableComparisons

  def shared_filter_spec
    {
      start: Date.parse('2023-10-01'),
      end: Date.parse('2024-09-30'),
      user_id: User.setup_system_user.id,
      coc_codes: ['XX-500', 'XX-501'],
    }.freeze
  end

  def default_filter
    ::Filters::HudFilterBase.new(shared_filter_spec)
  end

  def hmis_file_prefix
    'drivers/datalab_testkit/spec/fixtures/inputs/*'
  end

  def result_file_prefix
    'drivers/datalab_testkit/spec/fixtures/results/'
  end

  def result_file(name)
    File.join(result_file_prefix, name)
  end

  def setup(cleanup_enrollment_cocs: ENV['CLEANUP_ENROLLMENT_COCS'] == 'true')
    HmisCsvImporter::Utility.clear!
    GrdaWarehouse::Utility.clear!

    # Will use stored fixed point if one exists, instead of reprocessing the fixture, delete the pg_fixture to regenerate
    warehouse_fixture = PgFixtures.new(
      directory: 'drivers/datalab_testkit/spec/fixpoints',
      excluded_tables: default_excluded_tables,
      model: GrdaWarehouseBase,
    )
    app_fixture = PgFixtures.new(
      directory: 'drivers/datalab_testkit/spec/fixpoints',
      excluded_tables: default_excluded_tables,
      model: ApplicationRecord,
    )
    if warehouse_fixture.exists? && app_fixture.exists?
      puts "Restoring Fixtures #{Time.current}"
      warehouse_fixture.restore
      app_fixture.restore
      puts "Fixtures Restored #{Time.current}"
    else
      Dir.glob(hmis_file_prefix).select { |f| File.directory? f }.each do |file_path|
        # puts "*** #{file_path} ***"
        import_hmis_csv_fixture(file_path, run_jobs: false, skip_location_cleanup: true)
      end
      process_imported_fixtures(skip_location_cleanup: true)
      warehouse_fixture.store
      app_fixture.store
    end

    # Cleanup EnrollmentCoC to match production behavior where ProjectCleanup corrects mismatches
    # This matches what happens in the UI/production when skip_location_cleanup is false
    # Only run if explicitly requested via cleanup_enrollment_cocs: true
    cleanup_enrollment_cocs_for_tests if cleanup_enrollment_cocs
  end

  def cleanup
    GrdaWarehouse::Utility.clear!
  end

  # Cleanup EnrollmentCoC to match single-CoC projects
  # This replicates the logic from GrdaWarehouse::Tasks::ProjectCleanup#fix_client_locations
  # which runs in production but is skipped in tests via skip_location_cleanup: true
  def cleanup_enrollment_cocs_for_tests
    GrdaWarehouse::Hud::Project.find_each do |project|
      next unless project.enrollments.exists?

      coc_codes = project.project_cocs.map(&:effective_coc_code).uniq.
        select { |code| HudHelper.util.valid_coc?(code) }

      next unless coc_codes.present?

      # If project has exactly one CoC, fix all enrollments to match
      if coc_codes.count == 1
        project.enrollments.where.not(EnrollmentCoC: coc_codes).
          update_all(EnrollmentCoC: coc_codes.first, source_hash: nil)
      end

      # For multi-CoC projects, clear invalid CoCs
      project.enrollments.where.not(EnrollmentCoC: coc_codes).
        update_all(EnrollmentCoC: nil, source_hash: nil)
    end
  end

  def report_result
    # NOTE: SPM runs subsequent DQ reports, but sets @report_result, so we'll use that if available
    @report_result || ::HudReports::ReportInstance.last
  end

  # Generates a validations hash in the following format:
  # {
  #   'APR FY2026': {
  #     'Q7a' => [
  #       # Internal sum (note question for total is also Q7a)
  #       { total: 'B10', source: { question: 'Q7a', expression: 'C2+C3+C4+C5' }},
  #       # Equality to constant
  #       { total: 'B10', source: { question: 'Q7b', expression: 0 }},
  #       # Cross table comparison
  #       { total: 'B10', source: { question: 'Q4', expression: 'B7' }},
  #     ],
  #   },
  # }
  def validations
    validation_source_file = 'drivers/datalab_testkit/spec/fixtures/internal_consistency_validations/tup_validations.csv'
    validations = {}
    return validations unless File.exist?(validation_source_file)

    CSV.foreach(validation_source_file, headers: true) do |row|
      validations[row['Report']] ||= {}
      validations[row['Report']][row['Filename'].gsub('.csv', '')] ||= []
      validations[row['Report']][row['Filename'].gsub('.csv', '')] << {
        total: row['Field to validate'],
        source: {
          # NOTE: this will be getting a new column soon
          question: row['Filename'].gsub('.csv', ''),
          expression: row['Values to check against'],
        },
      }
    end
    validations
  end
end

RSpec.configure do |rspec|
  rspec.include_context 'datalab testkit context', include_shared: true
end
