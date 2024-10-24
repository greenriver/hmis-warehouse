namespace :dba do
  task :dry_run, [] => :environment do
    @dry_run = true
    # FIXME: repack_tables: needs more work to get repack added and versions in sync
    [:unbloat_indexes, :vacuum_tables, :index_drops, :show_cache_hits].each do |task|
      Rake::Task["dba:#{task}"].invoke
    end
  end

  # Useful in development to get something to paste
  task :show_bloated_sql_statements, [] => :environment do
    db = Dba::DatabaseBloat.new(ar_base_class: GrdaWarehouseBase)
    puts '-----------------'
    puts '-----------------'
    puts '-- indexes'
    puts db.send(:bloated_indexes_sql)
    puts ''
    puts '-----------------'
    puts '-----------------'
    puts '-- tables'
    puts db.send(:bloated_tables_sql)
    puts ''
    puts '-----------------'
    puts '-----------------'
    puts '-- unused indexes'
    puts db.send(:unused_indexes_sql)
  end

  task :unbloat, [] => [:unbloat_indexes, :repack_tables, :index_drops, :show_cache_hits]

  task :unbloat_indexes, [] => :environment do
    Dba::DatabaseBloat.all_databases!(:reindex!, dry_run: @dry_run)
  end

  task :vacuum_tables, [] => :environment do
    Dba::DatabaseBloat.all_databases!(:vacuum_full!, dry_run: @dry_run)
  end

  task :repack_tables, [] => :environment do
    Dba::DatabaseBloat.all_databases!(:repack!, dry_run: @dry_run)
  end

  task :index_drops, [] => :environment do
    Dba::DatabaseBloat.all_databases!(:index_drops!, dry_run: @dry_run)
  end

  task :show_cache_hits, [] => :environment do
    Dba::DatabaseBloat.all_databases!(:show_cache_hits!, dry_run: @dry_run)
  end

  # rails dba:partition['hmis_2022_enrollments']
  desc 'Partition big tables'
  task :partition, [:table] => [:environment] do |_t, args|
    if args[:table].present?
      pm = Dba::PartitionMaker.new(table_name: args[:table])
      if pm.no_table?
        Rails.logger.error "Skipping #{args[:table]} which couldn't be found"
      elsif pm.done?
        Rails.logger.info "Skipping #{args[:table]} which is done"
      else
        pm.run!
      end
    else
      Dba::PartitionAll.new.run!
    end
  end

  namespace :partition do
    desc "Get needed space"
    task :space_needed, [] => [:environment] do
      Dba::PartitionAll.new.space_needed
    end
  end
end
