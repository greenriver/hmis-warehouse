module HmisCsvFixtures
  def import_hmis_csv_fixture(
    file_path,
    data_source: nil,
    version: 'AutoMigrate',
    run_jobs: true,
    user: User.setup_system_user,
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
    elsif version == 'AutoMigrate'
      Importers::HmisAutoMigrate::Local.new(
        file_path: tmp_path,
        data_source_id: data_source.id,
        deidentified: deidentified,
        allowed_projects: allowed_projects,
      )
    else
      raise "Unsupported CSV version #{version}"
    end

    puts "Starting import: #{Time.now}"
    importer.import!
    FileUtils.rm_rf(tmp_path) if tmp_path
    process_imported_fixtures(user: user) if run_jobs

    Rails.cache.delete([user, 'access_groups']) # These are cached in project.rb etc for one minute, which is too long for tests
    importer
  end

  def process_imported_fixtures(user: User.setup_system_user)
    # puts "Start post processing: #{Time.now}"
    GrdaWarehouse::Tasks::ProjectCleanup.new.run!
    GrdaWarehouse::Tasks::ServiceHistory::Enrollment.batch_process_unprocessed!
    AccessGroup.maintain_system_groups
    AccessGroup.where(name: 'All Data Sources').first.add(user)
    Delayed::Worker.new.work_off
  end

  def cleanup_hmis_csv_fixtures
    # currently a no-op
  end
end
