###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
#
RSpec.shared_context 'FY2023 SPM enrollment context', shared_context: :metadata do
  def default_filter_definition
    {
      user_id: User.setup_system_user.id,
      start: Date.parse('2022-10-1'),
      end: Date.parse('2023-09-30'),
      coc_codes: ['MA-500'],
    }.freeze
  end

  def default_filter
    ::Filters::HudFilterBase.new(default_filter_definition)
  end

  def setup(export_directory)
    HmisCsvImporter::Utility.clear!
    GrdaWarehouse::Utility.clear!

    # Will use stored fixed point if one exists, instead of reprocessing the fixture, delete the pg_fixture to regenerate
    warehouse_fixture = PgFixtures.new(
      directory: "drivers/hud_spm_report/spec/fixpoints/#{export_directory}",
      excluded_tables: default_excluded_tables,
      model: GrdaWarehouseBase,
    )
    app_fixture = PgFixtures.new(
      directory: "drivers/hud_spm_report/spec/fixpoints/#{export_directory}",
      excluded_tables: default_excluded_tables,
      model: ApplicationRecord,
    )
    if warehouse_fixture.exists? && app_fixture.exists?
      puts "Restoring Fixtures #{Time.current}"
      warehouse_fixture.restore
      app_fixture.restore
      puts "Fixtures Restored #{Time.current}"
    else
      export_path = "drivers/hud_spm_report/spec/fixtures/files/fy2023/#{export_directory}"
      import_hmis_csv_fixture(export_path, run_jobs: false)
      process_imported_fixtures
      warehouse_fixture.store
      app_fixture.store
    end
  end

  def cleanup
    GrdaWarehouse::Utility.clear!
  end

  def run(filter, question_number)
    klass = HudSpmReport::Generators::Fy2023::Generator
    @report = HudReports::ReportInstance.from_filter(
      filter,
      klass.title,
      build_for_questions: [question_number],
    )

    @generator = klass.new(@report)
    @generator.run!

    @report_result = @generator.report
    @report_result.reload
  end
end
