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
    @delete_later = []
    GrdaWarehouse::Utility.clear!

    @data_source = GrdaWarehouse::DataSource.create(name: 'Green River', short_name: 'GR', source_type: :sftp)
    GrdaWarehouse::DataSource.create(name: 'Warehouse', short_name: 'W')
    GrdaWarehouse::ServiceHistoryServiceMaterialized.rebuild!
    import(file_path, @data_source)
    GrdaWarehouse::Tasks::IdentifyDuplicates.new.run!
    GrdaWarehouse::Tasks::ProjectCleanup.new.run!
    GrdaWarehouse::Tasks::ServiceHistory::Add.new.run!

    Delayed::Worker.new.work_off(2)
  end

  def import(file_path, data_source)
    source_file_path = File.join(file_path, 'source')
    import_path = File.join(file_path, data_source.id.to_s)
    # duplicate the fixture file as it gets manipulated
    FileUtils.cp_r(source_file_path, import_path)
    @delete_later << import_path unless import_path == source_file_path

    importer = Importers::HmisTwentyTwenty::Base.new(file_path: file_path, data_source_id: data_source.id, remove_files: false)
    importer.import!
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
    if @delete_later # rubocop:disable Style/SafeNavigation
      @delete_later.each do |path|
        FileUtils.rm_rf(path)
      end
    end
    Delayed::Job.delete_all
  end
end

RSpec.configure do |rspec|
  rspec.include_context 'path context', include_shared: true
end
