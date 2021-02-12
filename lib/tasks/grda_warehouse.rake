namespace :grda_warehouse do
  desc 'Setup a sample GRDA warehouse database'
  task setup: [:migrate, :seed_data_sources]

  task defrag: [:environment] do
    puts 'Finding fragmented indexes'
    sql_fragged_report = <<-SQL.strip_heredoc
      SELECT OBJECT_NAME(ind.OBJECT_ID) AS TableName,
      ind.name AS IndexName, indexstats.index_type_desc AS IndexType,
      indexstats.avg_fragmentation_in_percent
      FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, NULL) indexstats
      INNER JOIN sys.indexes ind
      ON ind.object_id = indexstats.object_id
      AND ind.index_id = indexstats.index_id
      WHERE indexstats.avg_fragmentation_in_percent > 30
      ORDER BY indexstats.avg_fragmentation_in_percent DESC
    SQL

    GrdaWarehouse::Hud::Base.connection.select_rows(sql_fragged_report).each do |table_name, index_name, index_type, percent_fragged|
      next unless index_name.present?
      puts "Reorganizing #{index_name} on #{table_name}. #{percent_fragged.round(2)}%) fragmented."
      GrdaWarehouse::Hud::Base.connection.execute("ALTER INDEX [#{index_name}] ON [#{table_name}] REORGANIZE")
    end

  end

  desc 'Empty the GRDA warehouse'
  task clear: [:environment] do
    GrdaWarehouse::Utility.clear!
  end

  desc 'Seed file types'
  task seed_file_types: [:environment] do
    GrdaWarehouse::AvailableFileTag.default_document_types.each do |doc|
      GrdaWarehouse::AvailableFileTag.where(doc).first_or_create
      ActsAsTaggableOn::Tag.where(name: doc[:name]).first_or_create
    end
  end

  desc 'Seed Data Sources'
  task seed_data_sources: [:environment] do
    if Rails.env.production?
      dnd = GrdaWarehouse::DataSource.where(name: 'Boston Department of Neighborhood Development').first_or_create
      dnd.file_path = '/mnt/hmis/dnd'
      dnd.source_type = 'samba'
      dnd.short_name = 'DND'
      dnd.munged_personal_id = true
      dnd.save

      nechv = GrdaWarehouse::DataSource.where(name: 'New England Center and Home for Veterans').first_or_create
      nechv.file_path = '/mnt/hmis/nechv'
      nechv.source_type = 'samba'
      nechv.short_name = 'NECHV'
      nechv.save

      bphc = GrdaWarehouse::DataSource.where(name: 'Boston Public Health Commission').first_or_create
      bphc.file_path = '/mnt/hmis/bphc'
      bphc.source_type = 'samba'
      bphc.short_name = 'BPHC'
      bphc.munged_personal_id = true
      bphc.save


      dnd_warehouse = GrdaWarehouse::DataSource.where(name: 'DND Warehouse').first_or_create
      dnd_warehouse.short_name = 'Warehouse'
      dnd_warehouse.save

      dnd_eto = GrdaWarehouse::DataSource.where(name: 'Department of Neighborhood Development: ETO').first_or_create
      dnd_eto.source_type = 'api'
      dnd_eto.short_name = 'DND ETO'
      dnd_eto.save

      ma_eto = GrdaWarehouse::DataSource.where(name: 'State of MA').first_or_create
      ma_eto.file_path = 'mnt/hmis/ma'
      ma_eto.source_type = 'samba'
      ma_eto.short_name = 'MA'
      ma_eto.munged_personal_id = true
      ma_eto.save
    elsif Rails.env.development? || Rails.env.staging?
      grda = GrdaWarehouse::DataSource.where(name: 'Green River').first_or_create
      grda.file_path = Rails.root.join.to_s << '/var/hmis/green_river'
      grda.source_type = 'samba'
      grda.short_name = 'GRDA'
      grda.munged_personal_id = true
      grda.save

      grda = GrdaWarehouse::DataSource.where(name: 'Blue Mountain').first_or_create
      grda.file_path = Rails.root.join.to_s << '/var/hmis/bm'
      grda.source_type = 'samba'
      grda.short_name = 'BM'
      grda.munged_personal_id = true
      grda.save

      grda = GrdaWarehouse::DataSource.where(name: 'Black Lake').first_or_create
      grda.file_path = Rails.root.join.to_s << '/var/hmis/bl'
      grda.source_type = 'samba'
      grda.short_name = 'BL'
      grda.munged_personal_id = true
      grda.save

      grda = GrdaWarehouse::DataSource.where(name: 'Orange Peninsula').first_or_create
      grda.file_path = Rails.root.join.to_s << '/var/hmis/op'
      grda.source_type = 'samba'
      grda.short_name = 'OP'
      grda.munged_personal_id = true
      grda.save

      grda = GrdaWarehouse::DataSource.where(name: 'Silver Island').first_or_create
      grda.file_path = Rails.root.join.to_s << '/var/hmis/si'
      grda.source_type = 'samba'
      grda.short_name = 'SI'
      grda.munged_personal_id = true
      grda.save

      dnd_warehouse = GrdaWarehouse::DataSource.where(name: 'HMIS Warehouse').first_or_create
      dnd_warehouse.short_name = 'Warehouse'
      dnd_warehouse.save
    end
  end

  desc 'Seed Grades'
  task seed_grades: [:environment] do
    GrdaWarehouse::Grades::Base.install_default_grades!
  end

  desc 'S3 Import HUD Zips from all Data Sources'
  task import_data_sources_s3: [:environment, 'log:info_to_stdout'] do
    Importers::HmisAutoDetect::S3.available_connections.each do |conf|
      next unless conf.active?

      options = {
        data_source_id: conf.data_source_id,
        region: conf.s3_region,
        access_key_id: conf.s3_access_key_id,
        secret_access_key: conf.s3_secret_access_key,
        bucket_name: conf.s3_bucket_name,
        path: conf.s3_path,
        file_password: conf.zip_file_password,
      }
      Importing::HudZip::FetchAndImportJob.perform_later(klass: 'Importers::HmisAutoDetect::S3', options: options)
    end
  end

  desc 'Sync from FTPS -> S3'
  task ftps_s3_sync: [:environment, 'log:info_to_stdout'] do
     GrdaWarehouse::LftpS3Sync.find_each(&:fetch_and_push)
  end

  desc 'Identify duplicates'
  task identify_duplicates: [:environment, 'log:info_to_stdout'] do
    GrdaWarehouse::Tasks::IdentifyDuplicates.new.run!
  end

  desc 'Generate Service History'
  task generate_service_history: [:environment, 'log:info_to_stdout'] do |task, args|
    GrdaWarehouse::Tasks::ServiceHistory::UpdateAddPatch.new.run!
  end

  desc 'Initialize ServiceHistortService homeless fields'
  task initialize_service_service_homelessness: [:environment, 'log:info_to_stdout'] do
    # Clients enrolled in homeless projects are homeless
    GrdaWarehouse::ServiceHistoryService.
      in_project_type(GrdaWarehouse::Hud::Project::HOMELESS_PROJECT_TYPES).
      update_all(homeless: true)

    # Clients enrolled in chronic projects are literally homeless
    GrdaWarehouse::ServiceHistoryService.
      in_project_type(GrdaWarehouse::Hud::Project::CHRONIC_PROJECT_TYPES).
      update_all(literally_homeless: true)

    # Clients enrolled in TH are not literally homeless
    # literally_homeless is defaulted to false, so we don't need to do this
    #
    # GrdaWarehouse::ServiceHistoryService.
    #   in_project_type(GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:th]).
    #   update_all(literally_homeless: false)

    # Clients enrolled in PH are literally homeless until their move-in date, or if they don't have one
    s_t = GrdaWarehouse::ServiceHistoryService.arel_table
    e_t = GrdaWarehouse::Hud::Enrollment.arel_table
    GrdaWarehouse::ServiceHistoryService.
      joins(service_history_enrollment: :enrollment).
      in_project_type(GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:ph]).
      where(s_t[:date].lt(e_t[:MoveInDate]).or(e_t[:MoveInDate].eq(nil))).
      update_all(homeless: true, literally_homeless: true)
  end

  desc 'Populate/replace nicknames'
  task nicknames_populate: [:environment, 'log:info_to_stdout'] do
    Nickname.populate!
  end

  desc 'Populate or update unique names'
  task update_unique_names: [:environment, 'log:info_to_stdout'] do
    UniqueName.update!
  end

  desc 'Calculate chronic homelessness [\'2017-01-15\']; defaults: date=Date.current'
  task :calculate_chronic_homelessness, [:date] => [:environment, 'log:info_to_stdout'] do |task, args|
    date = (args.date || Date.current).to_date
    GrdaWarehouse::Tasks::ChronicallyHomeless.new(date: date).run!
    GrdaWarehouse::Tasks::DmhChronicallyHomeless.new(date: date).run!
  end

  desc 'Calculate chronic homelessness [\'2015-01-15, 2017-01-15, 1, month\']; defaults: interval=1, unit=month'
  task :calculate_chronic_for_interval, [:start, :end, :interval, :unit] => [:environment, 'log:info_to_stdout'] do |task, args|
    raise 'dates required' unless args.start.present? && args.end.present?
    start_date = args.start.to_date
    end_date = args.end.to_date
    interval = (args.interval || 1).to_i
    unit = (args.unit || :month).to_sym
    while start_date < end_date
      GrdaWarehouse::Tasks::ChronicallyHomeless.new(date: start_date).run!
      GrdaWarehouse::Tasks::DmhChronicallyHomeless.new(date: start_date).run!
      GrdaWarehouse::Tasks::HudChronicallyHomeless.new(date: start_date).run!
      start_date += interval.send(unit)
    end
  end

  # rake grda_warehouse:anonymize_client_names['var/data/IL504']
  desc 'Anonymize all client names in Client.csv'
  task :anonymize_client_names, [:path] => [:environment, 'log:info_to_stdout'] do |task, args|
    raise 'path is required' unless args.path.present?
    path = args.path
    file = File.join(path, 'Client.csv')
    CSV.open("#{file.gsub('.csv', '.anon.csv')}", 'wb') do |csv|
      CSV.foreach(file, headers: true) do |row|
        csv << row.headers() if $. == 2
        row['FirstName'] = "First_#{row['PersonalID']}"
        row['LastName'] = "Last_#{row['PersonalID']}"

        # Cleanup Excel's nasty dates
        unless row['DateCreated'].include?('-')
          row['DOB'] = Date.strptime(row['DOB'], '%m/%d/%Y')&.strftime('%Y-%m-%d') if row['DOB'].present?
          row['DateCreated'] = Date.strptime(row['DateCreated'], '%m/%d/%Y %k:%M')&.to_date&.strftime('%Y-%m-%d %H-%M-%S')
          row['DateUpdated'] = Date.strptime(row['DateUpdated'], '%m/%d/%Y %k:%M')&.to_date&.strftime('%Y-%m-%d %H-%M-%S')
        end
        csv << row
      end
    end
  end

  desc 'Sanity Check Service History; defaults: n=50'
  task :sanity_check_service_history, [:n] => [:environment, 'log:info_to_stdout'] do |task, args|
    n = args.n
    GrdaWarehouse::Tasks::SanityCheckServiceHistory.new(( n || 50 ).to_i).run!
  end

  desc 'Full import routine'
  task daily: [:environment, 'log:info_to_stdout'] do
    Importing::RunDailyImportsJob.new.perform
  end

  desc 'Hourly tasks'
  task hourly: [:environment, 'log:info_to_stdout'] do
    begin
      Rake::Task['jobs:check_queue'].invoke
    rescue StandardError => e
      puts e.message
    end
    begin
      Rake::Task['grda_warehouse:send_health_emergency_notifications'].invoke
    rescue StandardError => e
      puts e.message
    end
    TextMessage::Message.send_pending! if RailsDrivers.loaded.include?(:text_message)
  end

  desc 'Mark the first residential service history record for clients for whom this has not yet been done; if you set the parameter to *any* value, all clients will be reset'
  task :first_residential_record, [:reset] => [:environment, 'log:info_to_stdout'] do |task, args|
    GrdaWarehouse::Tasks::EarliestResidentialService.new(args.reset).run!
  end

  desc 'Clean destination clients with no sources; defaults: max_allowed=50'
  task :clean_clients, [:max_allowed] => [:environment, 'log:info_to_stdout'] do |task, args|
    max_allowed = args.max_allowed
    GrdaWarehouse::Tasks::ClientCleanup.new(( max_allowed || 50 ).to_i).run!
  end

  desc 'Save Service History Snapshots'
  task :save_service_history_snapshots, [] => [:environment, 'log:info_to_stdout'] do |task, args|
    GrdaWarehouse::Hud::Client.needs_history_pdf.each do |client|
      job = Delayed::Job.enqueue ServiceHistory::ChronicVerificationJob.new(
        client_id: client.id,
        years: 3,
      ), queue: :short_running
    end
  end

  desc 'Warm Cohort Cache'
  task :warm_cohort_cache, [] => [:environment, 'log:info_to_stdout'] do |task, args|
    GrdaWarehouse::Cohort.delay(queue: :short_running).prepare_active_cohorts
  end

  desc 'Process Recurring HMIS Exports'
  task process_recurring_hmis_exports: [:environment] do
    GrdaWarehouse::Tasks::ProcessRecurringHmisExports.new.run!
  end

  namespace :secure_files do
    desc 'Remove expired secure files'
    task clean_expired: [:environment] do
      GrdaWarehouse::SecureFile.clean_expired
    end
  end

  desc 'Remove data based on import'
  task :remove_import_data, [:import_id] => [:environment, 'log:info_to_stdout'] do |task, args|
    import_id = args.import_id.to_i
    exit unless import_id.present? && import_id.to_s == args.import_id
    GrdaWarehouse::ImportRemover.new(import_id).run!
  end

  desc 'Cleanup fake CoC Codes'
  task :fake_coc_cleanup, [] => [:environment, 'log:info_to_stdout'] do |task, args|
    GrdaWarehouse::FakeData.find_each do |fake|
      next unless fake.map['CoCCode']

      fake.map['CoCCode'].each do |k, code|
        if HUD.cocs.keys.include?(code)
          fake.map['CoCCode'][k] = code
        else
          fake.map['CoCCode'][k] = HUD.cocs.keys.sample
        end
      end
      fake.save
    end
  end

  desc 'Invalidate incorrectly inherited move-in-date enrollments'
  task :invalidate_incorrect_move_ins, [] => [:environment, 'log:info_to_stdout'] do
    GrdaWarehouse::Tasks::ServiceHistory::Enrollment.where(MoveInDate: nil).
      where.not(RelationshipToHoH: 1).joins(:service_history_enrollment).
      merge(GrdaWarehouse::ServiceHistoryEnrollment.where.not(move_in_date: nil)).
      update_all(processed_as: nil)

    GrdaWarehouse::Tasks::ServiceHistory::Enrollment.queue_batch_process_unprocessed!
  end

  desc 'Force rebuild for homeless enrollments'
  task :force_rebuild_for_homeless_enrollments, [] => [:environment, 'log:info_to_stdout'] do |task, args|
    GrdaWarehouse::Tasks::ServiceHistory::Enrollment.where.not(MoveInDate: nil).invalidate_processing!
    GrdaWarehouse::Tasks::ServiceHistory::Enrollment.homeless.invalidate_processing!
    GrdaWarehouse::Tasks::ServiceHistory::Enrollment.unprocessed.pluck(:id).each_slice(250) do |batch|
      Delayed::Job.enqueue(::ServiceHistory::RebuildEnrollmentsByBatchJob.new(enrollment_ids: batch), queue: :long_running)
    end
    GrdaWarehouse::ServiceHistoryServiceMaterialized.delay(queue: :long_running).rebuild!
  end

  desc 'Send Health Emergency Notifications'
  task :send_health_emergency_notifications, [] => [:environment, 'log:info_to_stdout'] do |task, args|
    exit unless GrdaWarehouse::Config.get(:health_emergency)

    WarehouseReports::HealthEmergencyBatchNotifierJob.perform_now
  end

  desc 'Get shapes'
  task :get_shapes, [] => [:environment] do
    Rails.logger.info 'Downloading shapes of geometries (you need to set up your AWS environment to download)'
    FileUtils.chdir(Rails.root.join('shape_files'))
    system('./sync.from.s3')

    num_zips = `find . -name '*zip'`.split(/\n/).length
    if num_zips == 0
      # If you don't care about CoC/ZipCode shapes and want to just get through
      # the migration, just comment out this whole rake task. You can run it
      # later
      raise 'You didn\'t sync shape files correctly yet. Aborting'
    end

    Rails.logger.info 'Preparing shapes of geometries for insertion into database'
    FileUtils.chdir(Rails.root)
    system('./shape_files/zip_codes.census.2018/make.inserts') || exit
    system('./shape_files/CoC/make.inserts') || exit

    Rails.logger.info 'Inserting CoCs into the database, conserving RAM'
    GrdaWarehouse::Shape::ZipCode.delete_all
    GrdaWarehouse::Shape::CoC.delete_all
    ActiveRecord::Base.logger.silence do
      File.open('shape_files/CoC/coc.sql', 'r') do |fin|
        fin.each_line do |line|
          GrdaWarehouseBase.connection.execute(line)
        end
      end
    end

    Rails.logger.info 'Inserting zip codes into the database, conserving RAM (takes awhile)'
    ActiveRecord::Base.logger.silence do
      File.open('shape_files/zip_codes.census.2018/zip.codes.sql', 'r') do |fin|
        fin.each_line do |line|
          GrdaWarehouseBase.connection.execute(line)
        end
      end
    end

    Rails.logger.info 'Simplifying shapes for much faster UI'
    GrdaWarehouse::Shape::ZipCode.simplify!
    GrdaWarehouse::Shape::CoC.simplify!

    Rails.logger.info 'Done with shape importing'
  end
end
