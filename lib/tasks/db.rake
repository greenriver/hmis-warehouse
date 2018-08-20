namespace :db do
  namespace :migrate do
    desc "Call the db:migrate subvariant for all the different databases"
    task :all do
      puts `bin/rake db:migrate`
      puts `bin/rake warehouse:db:migrate`
      puts `bin/rake health:db:migrate`
    end
  end
end