###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

RSpec.shared_context 'path context FY2024', shared_context: :metadata do
  def shared_filter
    {
      start: Date.parse('2020-01-01'),
      end: Date.parse('2020-12-31'),
      coc_codes: ['XX-500'],
      user_id: User.setup_system_user.id,
    }.freeze
  end

  def default_filter
    so_project_id = GrdaWarehouse::Hud::Project.find_by(ProjectID: 'SO').id
    services_project_id = GrdaWarehouse::Hud::Project.find_by(ProjectID: 'SERVICES').id
    HudPathReport::Filters::PathFilter.new(shared_filter.merge(project_ids: [so_project_id, services_project_id]))
  end

  def run(filter, question_names)
    generator = HudPathReport::Generators::Fy2024::Generator
    generator.new(::HudReports::ReportInstance.from_filter(filter, generator.title, build_for_questions: Array.wrap(question_names))).run!
  end

  def default_setup_path
    'drivers/hud_path_report/spec/fixtures/files/fy2024/default'
  end

  def report_result
    ::HudReports::ReportInstance.last
  end

  def default_setup
    GrdaWarehouse::Utility.clear!
    # Will use stored fixed point if one exists, instead of reprocessing the fixture, delete the fixpoint to regenerate
    warehouse_fixture = PgFixtures.new(
      directory: 'drivers/hud_path_report/spec/fixpoints',
      excluded_tables: default_excluded_tables,
      model: GrdaWarehouseBase,
    )
    app_fixture = PgFixtures.new(
      directory: 'drivers/hud_path_report/spec/fixpoints',
      excluded_tables: ['versions'],
      model: ApplicationRecord,
    )
    if warehouse_fixture.exists? && app_fixture.exists?
      warehouse_fixture.restore
      app_fixture.restore
    else
      import_hmis_csv_fixture(default_setup_path, version: 'AutoMigrate')
      warehouse_fixture.store
      app_fixture.store
    end
  end

  def cleanup
    # Because we are only running the import once, we have to do our own DB and file cleanup
    GrdaWarehouse::Utility.clear!
    [
      HudReports::ReportInstance,
      HudReports::ReportCell,
      HudReports::UniverseMember,
      HudPathReport::Fy2020::PathClient,
    ].each do |klass|
      klass.connection.execute("TRUNCATE TABLE #{klass.quoted_table_name}")
    end

    Delayed::Job.delete_all
  end
end
