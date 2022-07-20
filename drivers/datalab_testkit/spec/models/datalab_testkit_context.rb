###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

RSpec.configure do
  RSpec.configuration.fixpoints_path = 'drivers/datalab_testkit/spec/fixpoints'
end

RSpec.shared_context 'datalab testkit context', shared_context: :metadata do
  def shared_filter_spec
    {
      start: Date.parse('2020-10-01'),
      end: Date.parse('2021-09-30'),
      user_id: User.setup_system_user.id,
      coc_codes: ['XX-500'],
    }.freeze
  end

  def default_filter
    ::Filters::HudFilterBase.new(shared_filter_spec)
  end

  def hmis_file_prefix
    'drivers/datalab_testkit/spec/fixtures/inputs/*'
  end

  def result_file_prefix
    'drivers/datalab_testkit/spec/fixtures/'
  end

  def result_file(name)
    File.join(result_file_prefix, name)
  end

  def setup
    HmisCsvImporter::Utility.clear!
    GrdaWarehouse::Utility.clear!

    warehouse = GrdaWarehouseBase.connection

    # Will use stored fixed point if one exists, instead of reprocessing the fixture, delete the fixpoint to regenerate
    # Fixpoints runs out of memory reloading this, so it is disabled for now
    if Fixpoint.exists? :datalab_2_0_app
      restore_fixpoint :datalab_2_0_app
      restore_fixpoint :datalab_2_0_warehouse, connection: warehouse
    else
      Dir.glob(hmis_file_prefix).select { |f| File.directory? f }.each do |file_path|
        puts "*** #{file_path} ***"
        import_hmis_csv_fixture(file_path, run_jobs: false)
      end
      process_imported_fixtures
      store_fixpoint :datalab_2_0_app
      store_fixpoint :datalab_2_0_warehouse, connection: warehouse
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
