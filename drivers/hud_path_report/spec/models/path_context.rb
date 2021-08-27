###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

RSpec.configure do |config|
  config.fixpoints_path = 'drivers/hud_path_report/spec/fixpoints' # Doesn't seem to work in CI?
end

RSpec.shared_context 'path context', shared_context: :metadata do
  def shared_filter
    @user = User.setup_system_user
    {
      start: Date.parse('2020-01-01'),
      end: Date.parse('2020-12-31'),
      coc_codes: ['XX-500'],
      user_id: @user.id,
    }.freeze
  end

  def default_filter
    so_project_id = GrdaWarehouse::Hud::Project.find_by(ProjectID: 'SO').id
    services_project_id = GrdaWarehouse::Hud::Project.find_by(ProjectID: 'SERVICES').id
    HudPathReport::Filters::PathFilter.new(shared_filter.merge(project_ids: [so_project_id, services_project_id]))
  end

  def run(filter, question_name)
    generator = HudPathReport::Generators::Fy2020::Generator
    generator.new(::HudReports::ReportInstance.from_filter(filter, generator.title, build_for_questions: [question_name])).run!
  end

  def default_setup_path
    'drivers/hud_path_report/spec/fixtures/files/fy2020/default'
  end

  def report_result
    ::HudReports::ReportInstance.last
  end

  def default_setup
    # Will use stored fixed point if one exists, instead of reprocessing the fixture, delete the fixpoint to regenerate
    warehouse = GrdaWarehouseBase.connection

    if Fixpoint.exists? :path_hmis_export_app
      restore_fixpoint :path_hmis_export_app
      restore_fixpoint :path_hmis_export_warehouse, connection: warehouse
    else
      setup(default_setup_path)
      store_fixpoint :path_hmis_export_app
      store_fixpoint :path_hmis_export_warehouse, connection: warehouse
    end
  end

  def setup(file_path)
    HmisCsvTwentyTwenty::Utility.clear!
    GrdaWarehouse::Utility.clear!
    @data_source = GrdaWarehouse::DataSource.where(name: 'Green River', short_name: 'GR', source_type: :sftp).first_or_create!
    GrdaWarehouse::DataSource.where(name: 'Warehouse', short_name: 'W').first_or_create!
    import_hmis_csv_fixture(
      file_path,
      data_source: @data_source,
      version: '2020',
      run_jobs: true,
    )
    @user = User.setup_system_user
    @user.add_viewable(@data_source)
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

RSpec.configure do |rspec|
  rspec.include_context 'path context', include_shared: true
end
