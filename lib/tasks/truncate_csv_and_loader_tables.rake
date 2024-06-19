# frozen_string_literal: true

desc 'truncate HUD loader csv and importer tables'
# rails truncate_csv_and_loader_tables[2022]
# rails truncate_csv_and_loader_tables[2022,confirmed]
task :truncate_csv_and_loader_tables, [:year, :confirm] => :environment do |_task, args|
  year = args.year
  raise 'valid year required' unless year =~ /\A202\d\z/

  connection = HmisCsvImporter::Importer::ImporterLog.connection
  tables = connection.tables.
    # matches hmis_csv_2024_project_cocs and hmis_2024_project_cocs
    grep(/\Ahmis_(csv_)?#{year}_[a-z_]+\z/).
    # keep projects and export tables
    grep_v(/#{year}_(projects|exports)\z/).
    sort

  raise "no tables found for year:#{year}" if tables.empty?

  summary_message = "Truncating #{tables.size} tables from \"#{connection.current_database}\": #{tables.join(', ')}"
  if args.confirm != 'confirmed'
    puts summary_message
    puts 'Are you sure you want to proceed? (yes/no)'
    if $stdin.gets.chomp.downcase == 'yes'
      puts 'truncating...'
    else
      puts 'aborting...'
      exit(1)
    end
  end
  Rails.logger.info summary_message

  tables.each do |table|
    connection.execute("TRUNCATE #{table} RESTART IDENTITY RESTRICT")
    # note: according to postgres docs, disk space is reclaimed immediately after truncate without requiring a vacuum
  end
end
