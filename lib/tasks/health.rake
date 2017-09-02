task spec: ["health:db:test:prepare"]

require 'dotenv'
Dotenv.load('.env', '.env.local')

namespace :health do
 
  desc "Import and match health data"
  task daily: [:environment, "log:info_to_stdout"] do
    Importing::RunHealthImportJob.new.perform
  end

  
  desc "Import development data"
  task :dev_import, [:reset] => [:environment, "log:info_to_stdout"] do |task, args|
    unless Rails.env.development?
      Rails.logger.warn 'Refusing to import development data into non-development environment'
    else
      # clear out any previous patients and associated data
      if args.reset.present?
        Rails.logger.info 'Removing all health data'
        Health::Base.known_sub_classes.each do |klass|
          klass.delete_all
        end
        Health::Claims::Base.known_sub_classes.each do |klass|
          klass.delete_all
        end
      end
      Health::Tasks::ImportEpic.new(load_locally: true).run!
      Health::Tasks::ImportClaims.new().run!
      # pick some new clients for the new patients
      Health::Tasks::PatientClientMatcher.new.run!
      # if anyone didn't get matched, just pick a random one, this IS development
      Health::Patient.unprocessed.each do |patient|
        client_id = GrdaWarehouse::Hud::Client.destination.
          where.not(id: Health::Patient.pluck(:client_id)).
          order('RANDOM()').limit(5).sample.id
        patient.update(client_id: client_id)
      end
    end
  end


  # DB related, provides health:db:migrate etc.
  namespace :db do |ns|
 
    task :drop do
      Rake::Task["db:drop"].invoke
    end
 
    task :create do
      Rake::Task["db:create"].invoke
    end
 
    task :setup do
      Rake::Task["db:setup"].invoke
    end
 
    task :migrate do
      Rake::Task["db:migrate"].invoke
    end
 
    task :rollback do
      Rake::Task["db:rollback"].invoke
    end
 
    task :seed do
      Rake::Task["db:seed"].invoke
    end
 
    task :version do
      Rake::Task["db:version"].invoke
    end
 
    namespace :schema do
      task :load do
        Rake::Task["db:schema:load"].invoke
      end
 
      task :dump do
        Rake::Task["db:schema:dump"].invoke
      end
    end
 
    namespace :test do
      task :prepare do
        Rake::Task["db:test:prepare"].invoke
      end
    end
 
    # append and prepend proper tasks to all the tasks defined here above
    ns.tasks.each do |task|
      task.enhance ["health:set_custom_config"] do
        Rake::Task["health:revert_to_original_config"].invoke
      end
    end
  end
 
  task :set_custom_config do
    # save current vars
    @original_config = {
      env_schema: ENV['SCHEMA'],
      config: Rails.application.config.dup
    }
 
    # set config variables for custom database
    ENV['SCHEMA'] = "db/health/schema.rb"
    Rails.application.config.paths['db'] = ["db/health"]
    Rails.application.config.paths['db/migrate'] = ["db/health/migrate"]
    Rails.application.config.paths['db/seeds'] = ["db/health/seeds.rb"]
    Rails.application.config.paths['config/database'] = ["config/database_health.yml"]
    db_config = Rails.application.config.paths['config/database'].to_a.first
    ActiveRecord::Base.establish_connection YAML.load(ERB.new(File.read(db_config)).result)[Rails.env]
  end
 
  task :revert_to_original_config do
    # reset config variables to original values
    db_config = Rails.application.config.paths['config/database'].to_a.first
    ActiveRecord::Base.establish_connection YAML.load(ERB.new(File.read(db_config)).result)[Rails.env]

    ENV['SCHEMA'] = @original_config[:env_schema]
    Rails.application.config = @original_config[:config]
  end
end
