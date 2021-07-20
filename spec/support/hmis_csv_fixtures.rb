module HmisCsvFixtures
  def import_hmis_csv_fixture(
    file_path,
    data_source: nil,
    version: '2020',
    run_jobs: true,
    allowed_projects: nil,
    deidentified: nil
  )
    unless data_source
      data_source = GrdaWarehouse::DataSource.where(
        name: 'Green River',
        short_name: 'GR',
        source_type: :sftp,
      ).first_or_create!
      GrdaWarehouse::DataSource.where(
        name: 'Warehouse',
        short_name: 'W',
      ).first_or_create!
    end

    @data_source = data_source
    source_file_path = File.join(file_path, 'source')

    # duplicate the fixture folder since some
    # importers expect data in "#{file_path}/#{data_source_id}"
    # and to be able to tamper with its contents
    # TODO: fix importers to avoid mutating the source!
    tmp_path = File.join(file_path, data_source.id.to_s)
    FileUtils.cp_r(source_file_path, tmp_path)

    importer = if version == '2020'
      HmisCsvTwentyTwenty::Loader::Loader.new(
        file_path: tmp_path,
        data_source_id: data_source.id,
        deidentified: deidentified,
      )
    elsif version == 'AutoDetect'
      Importers::HmisAutoDetect::Local.new(
        file_path: tmp_path,
        data_source_id: data_source.id,
        deidentified: deidentified,
        allowed_projects: allowed_projects,
      )
    else
      raise "Unsupported CSV version #{version}"
    end

    importer.import!
    FileUtils.rm_rf(tmp_path) if tmp_path

    if run_jobs
      # 2020 always runs this so we dont need to do it twice
      GrdaWarehouse::Tasks::IdentifyDuplicates.new.run! unless version == '2020'

      GrdaWarehouse::Tasks::ProjectCleanup.new.run!
      GrdaWarehouse::Tasks::ServiceHistory::Add.new.run!
      AccessGroup.maintain_system_groups

      Delayed::Worker.new.work_off
    end

    importer
  end

  def cleanup_hmis_csv_fixtures
    # currently a no-op
  end
end
