namespace :db do
  namespace :migrate do
    desc "Call the db:migrate subvariant for all the different databases"
    task :all do
      Rake::Task["db:migrate"].invoke
      Rake::Task["warehouse:db:migrate"].invoke
      Rake::Task["health:db:migrate"].invoke
    end
  end
end