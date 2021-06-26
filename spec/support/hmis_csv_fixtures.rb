module HmisCsvFixtures
  def import_hmis_csv_fixture(file_path, version: '2020', data_source: nil, run_jobs: true)
    unless data_source
      data_source = GrdaWarehouse::DataSource.where(
        name: 'Green River',
        short_name: 'GR',
        source_type: :sftp
      ).first_or_create
      GrdaWarehouse::DataSource.where(
        name: 'Warehouse',
        short_name: 'W'
      ).first_or_create
    end

    @data_source = data_source
    source_file_path = File.join(file_path, 'source')

    # duplicate the fixture folder since the import is
    # expecting "#{file_path}/#{data_source.id}" and to be able
    # to tamper with its contents
    tmp_path = File.join(file_path, data_source.id.to_s)
    FileUtils.cp_r(source_file_path, tmp_path)

    importer = if version == '6.11'
      Importers::HMISSixOneOne::Bases.new(
        file_path: file_path,
        data_source_id: data_source.id
      )
    elsif version == '2020'
      HmisCsvTwentyTwenty::Loader::Loader.new(
        file_path: tmp_path,
        data_source_id: data_source.id
      )
    else
      raise "Unsupported CSV version #{version}"
    end
    importer.import!

    if run_jobs
      GrdaWarehouse::Tasks::IdentifyDuplicates.new.run!
      GrdaWarehouse::Tasks::ProjectCleanup.new.run!
      GrdaWarehouse::Tasks::ServiceHistory::Add.new.run!
      AccessGroup.maintain_system_groups

    end
    Delayed::Worker.new.work_off
  ensure
    FileUtils.rm_rf(tmp_path) if tmp_path

    nil # no useful return
  end

  def cleanup_hmis_csv_fixtures
    # currently a no-op
  end
end
