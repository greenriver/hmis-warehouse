# frozen_string_literal: true

desc 'truncate HUD loader csv and importer tables'
# rails truncate_csv_and_loader_tables[2022]
# rails truncate_csv_and_loader_tables[2022,confirmed]
task :truncate_csv_and_loader_tables, [:year, :confirm] => :environment do |_task, args|
  year = args.year
  raise 'valid year required' unless year =~ /\A202\d\z/

  models = []
  case year
  when '2020'
    HmisCsvTwentyTwenty.importable_files_map.values.each do |name|
      next if name =~ /\A(Project|Export)\z/

      models << "HmisCsvTwentyTwenty::Loader::#{name}".constantize
      models << "HmisCsvTwentyTwenty::Importer::#{name}".constantize
    end
  when '2022'
    HmisCsvTwentyTwentyTwo.importable_files_map.values.each do |name|
      next if name =~ /\A(Project|Export)\z/

      models << "HmisCsvTwentyTwentyTwo::Loader::#{name}".constantize
      models << "HmisCsvTwentyTwentyTwo::Importer::#{name}".constantize
    end
  end
  raise "no tables found for year:#{year}" if models.empty?

  summary_message = "Truncating #{models.size} tables: #{models.map(&:table_name).sort.join(', ')}"
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

  models.each do |model|
    model.connection.execute("TRUNCATE #{model.table_name} RESTART IDENTITY RESTRICT")
    # note: according to postgres docs, disk space is reclaimed immediately after truncate without requiring a vacuum
  end
end
