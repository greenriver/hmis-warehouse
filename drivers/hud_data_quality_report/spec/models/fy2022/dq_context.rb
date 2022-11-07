###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

RSpec.shared_context 'dq context FY2022', shared_context: :metadata do
  def shared_filter
    {
      start: Date.parse('2019-01-01'),
      end: Date.parse('2019-12-31'),
      coc_codes: ['XX-500'],
      user_id: User.setup_system_user.id,
    }.freeze
  end

  def default_filter
    project_id = GrdaWarehouse::Hud::Project.find_by(ProjectID: 'DEFAULT-ES').id
    ::Filters::HudFilterBase.new(shared_filter.merge(project_ids: [project_id]))
  end

  def race_filter
    project_id = GrdaWarehouse::Hud::Project.find_by(ProjectID: 'DEFAULT-ES').id
    ::Filters::HudFilterBase.new(shared_filter.merge(project_ids: [project_id])).update(
      shared_filter.merge(
        { 'races' => ['Asian'] },
      ),
    )
  end

  def age_filter
    project_id = GrdaWarehouse::Hud::Project.find_by(ProjectID: 'DEFAULT-ES').id
    ::Filters::HudFilterBase.new(shared_filter.merge(project_ids: [project_id])).update(
      shared_filter.merge(
        { 'age_ranges' => ['under_eighteen'] },
      ),
    )
  end

  def night_by_night_shelter
    project_id = GrdaWarehouse::Hud::Project.find_by(ProjectID: 'NBN').id
    ::Filters::HudFilterBase.new(shared_filter.merge(project_ids: [project_id]))
  end

  def run(filter, question_name)
    generator = HudDataQualityReport::Generators::Fy2022::Generator
    generator.new(::HudReports::ReportInstance.from_filter(filter, generator.title, build_for_questions: [question_name])).run!(email: false)
  end

  def default_setup_path
    'drivers/hud_data_quality_report/spec/fixtures/files/fy2022/default'
  end

  def report_result
    ::HudReports::ReportInstance.last
  end

  def default_setup
    # Will use stored fixed point if one exists, instead of reprocessing the fixture, delete the fixpoint to regenerate
    warehouse_fixture = PgFixtures.new(
      directory: 'drivers/hud_data_quality_report/spec/fixpoints',
      excluded_tables: default_excluded_tables,
      model: GrdaWarehouseBase,
    )
    app_fixture = PgFixtures.new(
      directory: 'drivers/hud_data_quality_report/spec/fixpoints',
      excluded_tables: ['versions'],
      model: ApplicationRecord,
    )
    if warehouse_fixture.exists? && app_fixture.exists?
      GrdaWarehouse::Utility.clear!
      warehouse_fixture.restore
      app_fixture.restore
    else
      setup(default_setup_path)
      warehouse_fixture.store
      app_fixture.store
    end
  end

  def setup(file_path)
    HmisCsvImporter::Utility.clear!
    GrdaWarehouse::Utility.clear!
    import_hmis_csv_fixture(file_path, version: 'AutoMigrate')
  end

  def cleanup
    # We don't need to do anything here currently
  end
end

RSpec.configure do |rspec|
  rspec.include_context 'dq context FY2022', include_shared: true
end
