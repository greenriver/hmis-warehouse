namespace :grda_warehouse do
  desc "Setup a sample GRDA warehouse database"
  task setup: [:migrate, :seed_data_sources]

  desc "Migrate the GRDA warehouse"
  task migrate: [:environment] do
    db_conf = Rails.configuration.database_configuration
    ActiveRecord::Base.establish_connection db_conf["#{Rails.env}_grda_warehouse"]
    ActiveRecord::Migrator.migrate("db/grda_warehouse/")
  end

  desc "Create the GRDA warehouse"
  task create: [:environment] do
    db_conf = Rails.configuration.database_configuration
    ActiveRecord::Base.connection.create_database "#{Rails.env}_grda_warehouse", db_conf["#{Rails.env}_grda_warehouse"]
  end


  task defrag: [:environment] do
    puts "Finding fragmented indexes"
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

  desc "Roll-back the GRDA warehouse"
  task rollback: [:environment] do
    db_conf = Rails.configuration.database_configuration
    ActiveRecord::Base.establish_connection db_conf["#{Rails.env}_grda_warehouse"]
    ActiveRecord::Migrator.rollback("db/grda_warehouse/")
  end

  desc "run the down method of the grda migration specified by VERSION"
  task down: [:environment] do
    version = ENV["VERSION"] ? ENV["VERSION"].to_i : nil
    raise "VERSION is required - To go down one migration, run db:rollback" unless version
    db_conf = Rails.configuration.database_configuration
    ActiveRecord::Base.establish_connection db_conf["#{Rails.env}_grda_warehouse"]
    ActiveRecord::Migrator.run(:down, "db/grda_warehouse/", version)
    #db_namespace["_dump"].invoke
  end

  desc "run the up method of the grda migration specified by VERSION"
  task up: [:environment] do
    version = ENV["VERSION"] ? ENV["VERSION"].to_i : nil
    raise "VERSION is required - To go down one migration, run db:rollback" unless version
    db_conf = Rails.configuration.database_configuration
    ActiveRecord::Base.establish_connection db_conf["#{Rails.env}_grda_warehouse"]
    ActiveRecord::Migrator.run(:up, "db/grda_warehouse/", version)
    #db_namespace["_dump"].invoke
  end

  desc "Empty the GRDA warehouse"
  task clear: [:environment] do
    GrdaWarehouse::Utility.clear!
  end

  desc "Seed Data Sources"
  task seed_data_sources: [:environment] do
    if Rails.env.production? || Rails.env.staging?
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
    elsif Rails.env.development?
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

      dnd_warehouse = GrdaWarehouse::DataSource.where(name: 'DND Warehouse').first_or_create
      dnd_warehouse.short_name = 'Warehouse'
      dnd_warehouse.save
    end
  end

  desc "Import Many HUD CSVs for development"
  task :import_dev_hud_csvs, [:environment, "log:info_to_stdout"] do
    # loop over data sources, looking for sub directories, find the first one
    # copy all files into the data source import path
    # delete the folder, run samba import for that DS
    GrdaWarehouse::DataSource.importable.each do |ds|
      directories = Dir["#{ds.file_path}/*"].select{ |f| File.directory?(f)}
      directories.each do |dir|
        puts "Moving #{dir}/* to #{ds.file_path}"
        Dir["#{dir}/*"].each do |f|
          FileUtils.mv(f, ds.file_path) if File.extname(f) == '.csv'
        end
        puts "Removing #{dir}"
        FileUtils.rmdir(dir)
        puts "Importing #{ds.id}"
        Importers::Samba.new(ds.id).run!
      end
    end
  end

  desc "Dump Many HUD CSVs from Production for Development"
  task :dump_hud_csvs_for_dev, [:n] => [:environment] do |t, args|
    GrdaWarehouse::Tasks::DumpHmisSubset.new(n: args.n || 500).run!
  end

  desc "Import HUD Zips from all Data Sources"
  task :import_data_sources, [:data_source_id] => [:environment] do |t, args|
    Importers::Samba.new(args.data_source_id).run!
  end

  desc "Identify duplicates"
  task identify_duplicates: [:environment, "log:info_to_stdout"] do
    GrdaWarehouse::Tasks::IdentifyDuplicates.new.run!
  end

  desc "Generate Service History"
  task generate_service_history: [:environment, "log:info_to_stdout"] do |task, args|
    GrdaWarehouse::Tasks::GenerateServiceHistory.new.run!
  end

  desc "Populate/replace nicknames"
  task nicknames_populate: [:environment, "log:info_to_stdout"] do
    Nickname.populate!
  end

  desc "Populate or update unique names"
  task update_unique_names: [:environment, "log:info_to_stdout"] do
    UniqueName.update!
  end

  desc "Calculate chronic homelessness ['2017-01-15']; defaults: date=Date.today"
  task :calculate_chronic_homelessness, [:date] => [:environment, "log:info_to_stdout"] do |task, args|
    date = (args.date || Date.today).to_date
    GrdaWarehouse::Tasks::ChronicallyHomeless.new(date: date).run!
  end

  desc "Calculate chronic homelessness ['2015-01-15, 2017-01-15, 1, month']; defaults: interval=1, unit=month"
  task :calculate_chronic_for_interval, [:start, :end, :interval, :unit] => [:environment, "log:info_to_stdout"] do |task, args|
    raise 'dates required' unless args.start.present? && args.end.present?
    start_date = args.start.to_date
    end_date = args.end.to_date
    interval = (args.interval || 1).to_i
    unit = (args.unit || :month).to_sym
    while start_date < end_date
      GrdaWarehouse::Tasks::ChronicallyHomeless.new(date: start_date).run!
      start_date += interval.send(unit)
    end
  end

  desc "Calculate DMH chronic homelessness ['2017-01-15']; defaults: date=Date.today"
  task :calculate_dmh_chronic_homelessness, [:date] => [:environment, "log:info_to_stdout"] do |task, args|
    date = (args.date || Date.today).to_date
    GrdaWarehouse::Tasks::DmhChronicallyHomeless.new(date: date).run!
  end

  desc "Calculate DMH chronic homelessness ['2015-01-15, 2017-01-15, 1, month']; defaults: interval=1, unit=month"
  task :calculate_dmh_chronic_for_interval, [:start, :end, :interval, :unit] => [:environment, "log:info_to_stdout"] do |task, args|
    raise 'dates required' unless args.start.present? && args.end.present?
    start_date = args.start.to_date
    end_date = args.end.to_date
    interval = (args.interval || 1).to_i
    unit = (args.unit || :month).to_sym
    while start_date < end_date
      GrdaWarehouse::Tasks::DmhChronicallyHomeless.new(date: start_date).run!
      start_date += interval.send(unit)
    end
  end

  desc "Sanity Check Service History; defaults: n=50"
  task :sanity_check_service_history, [:n] => [:environment, "log:info_to_stdout"] do |task, args|
    n = args.n
    GrdaWarehouse::Tasks::SanityCheckServiceHistory.new(( n || 50 ).to_i).run!
  end

  desc "Full import routine"
  task daily: [:environment, "log:info_to_stdout"] do
    Importing::RunDailyImportsJob.new.perform
  end

  desc "Mark the first residential service history record for clients for whom this has not yet been done; if you set the parameter to *any* value, all clients will be reset"
  task :first_residential_record, [:reset] => [:environment, "log:info_to_stdout"] do |task, args|
    GrdaWarehouse::Tasks::EarliestResidentialService.new(args.reset).run!
  end

  desc "Clean destination clients with no sources; defaults: max_allowed=50"
  task :clean_clients, [:max_allowed] => [:environment, "log:info_to_stdout"] do |task, args|
    max_allowed = args.max_allowed
    GrdaWarehouse::Tasks::ClientCleanup.new(( max_allowed || 50 ).to_i).run!
  end
end