namespace :test do

  desc "create data files; all records relevant to a fixed number of staging clients are collected and dumped to CSV files; defaults: directory=tmp/test_data, n=50"
  task :make_csv, [:directory, :n] => [:environment, "log:info_to_stdout"] do |task,args|
    n   = ( args.n.presence || 50 ).to_i
    dir = args.directory.presence || 'tmp/test_data'
    GrdaWarehouse::Tasks::TestData.new( n: n, dir: dir ).run!
  end

  desc "import test HUD data into testing database, obliterating whatever is already there; defaults: directory=tmp/test_data"
  task :refresh_data, [:directory] => [:environment, "log:info_to_stdout"] do |task, args|
    dir = args.directory.presence || 'tmp/test_data'
    GrdaWarehouse::Tasks::RefreshData.new( dir: dir ).run!
  end

  desc "perform all tasks required to prepare the test database in sequence using default parameters"
  task :prepare_all => [:environment, "log:info_to_stdout" ] do
    {
      'test:make_csv' => [],
      'test:refresh_data' => [],
      'grda_warehouse:identify_duplicates' => [],
      'grda_warehouse:generate_service_history' => [true],
    }.each do |task, args|
      Rake::Task[task].invoke *args
      FileUtils.chdir Rails.root
    end
    Nickname.populate!
    UniqueName.update!
    {
      'census:import' => [],
      'census:average' => [],
      'grda_warehouse:first_residential_record' => [],
      'grda_warehouse:calculate_chronic_homelessness' => [],
      'grda_warehouse:clean_clients' => [ nil, true ],
      'similarity:initialize' => [],
    }.each do |task, args|
      Rake::Task[task].invoke *args
      FileUtils.chdir Rails.root
    end
  end

end