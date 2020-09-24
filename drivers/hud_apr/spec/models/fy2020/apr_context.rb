RSpec.shared_context 'apr context', shared_context: :metadata do
  def default_options
    {
      generator_class: 'HudApr::Generators::Apr::Fy2020::Generator',
      start_date: Date.parse('2016-10-01'),
      end_date: Date.parse('2017-09-30'),
      coc_code: 'XX-500',
      project_ids: ['240'],
      user_id: 0,
    }.freeze
  end

  def night_by_night_shelter
    {
      project_ids: ['882'],
    }
  end

  def default_setup_path
    'drivers/hud_apr/spec/fixtures/files/hud_hmis_export'
  end

  def report_result
    HudReports::ReportInstance.last
  end

  def setup(file_path)
    @delete_later = []
    GrdaWarehouse::Utility.clear!

    @data_source = GrdaWarehouse::DataSource.create(name: 'Green River', short_name: 'GR', source_type: :sftp)
    GrdaWarehouse::DataSource.create(name: 'Warehouse', short_name: 'W')
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
    @delete_later.each do |path|
      FileUtils.rm_rf(path)
    end
    Delayed::Job.delete_all
  end
end

RSpec.configure do |rspec|
  rspec.include_context 'apr context', include_shared: true
end
