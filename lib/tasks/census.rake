namespace :census do

  desc "import data into the census table; unless you provide a truthy replace_all value, only the most recent year's values are replaced"
  task :import, [:replace_all] => [:environment, "log:info_to_stdout"] do |task, args|
    GrdaWarehouse::Tasks::CensusImport.new(args.replace_all).run!
  end
end
