###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

RSpec.shared_context 'datalab testkit context', shared_context: :metadata do
  def shared_filter_spec
    {
      start: Date.parse('2021-10-01'),
      end: Date.parse('2022-09-30'),
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

  def setup
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
      excluded_tables: ['versions'],
      model: ApplicationRecord,
    )
    if warehouse_fixture.exists? && app_fixture.exists?
      warehouse_fixture.restore
      app_fixture.restore
    else
      Dir.glob(hmis_file_prefix).select { |f| File.directory? f }.each do |file_path|
        # puts "*** #{file_path} ***"
        import_hmis_csv_fixture(file_path, run_jobs: false)
      end
      process_imported_fixtures
      warehouse_fixture.store
      app_fixture.store
    end
  end

  def cleanup
    GrdaWarehouse::Utility.clear!
  end

  def report_result
    ::HudReports::ReportInstance.last
  end

  require_relative './table_comparisons'
end

RSpec.configure do |rspec|
  rspec.include_context 'datalab testkit context', include_shared: true
end
