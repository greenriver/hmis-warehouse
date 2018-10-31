task spec: ["health:db:test:prepare"]

require 'dotenv'
Dotenv.load('.env', '.env.local')

namespace :health do

  desc "Import and match health data"
  task daily: [:environment, "log:info_to_stdout"] do
    Importing::RunHealthImportJob.new.perform
  end

  desc "Create Healthcare for the Homeless Data Source"
  task setup_healthcare_ds: [:environment, "log:info_to_stdout"] do
    ds = GrdaWarehouse::DataSource.where(short_name: 'Health', name: 'Healthcare for the Homeless').first_or_initialize
    ds.source_type = :authoritative
    ds.visible_in_window = true
    ds.authoritative = true
    ds.save!
  end

  desc "Create Health::AccountableCareOrganization"
  task setup_initial_aco: [:environment, "log:info_to_stdout"] do
    Health::AccountableCareOrganization.create!(name: 'MassHealth')
  end

  desc "Import patient Referrals"
  task import_patient_referrals: [:environment, "log:info_to_stdout"] do
    Health::Tasks::ImportPatientReferrals.new.import!
    Health::Tasks::ImportPatientReferralRefreshes.new.import!
  end

  desc "Fix HealthFile relationships"
  task fix_health_file_relationships: [:environment, "log:info_to_stdout"] do
    Health::HealthFile.where(parent_id: nil).each do |file|
      case file.type
      when "Health::SsmFile"
        form_id = Health::SelfSufficiencyMatrixForm.where(health_file_id: file.id).pluck(:id).first
        if !form_id # re-classify any SSMFiles that were attached to care plans as CareplanFiles
          form_id = Health::Careplan.where(health_file_id: file.id).maximum(:id)
          file.assign_attributes( type: 'Health::CareplanFile')
        end
      when "Health::ParticipationFormFile"
        form_id = Health::ParticipationForm.where(health_file_id: file.id).pluck(:id).first
      when "Health::ComprehensiveHealthAssessmentFile"
        form_id = Health::ComprehensiveHealthAssessment.where(health_file_id: file.id).pluck(:id).first
      when "Health::SdhCaseManagementNoteFile"
        form_id = Health::SdhCaseManagementNote.where(health_file_id: file.id).pluck(:id).first
      when "Health::ReleaseFormFile"
        form_id = Health::ReleaseForm.where(health_file_id: file.id).pluck(:id).first
      when "Health::SignableDocumentFile"
        form_id = Health::SignableDocument.where(health_file_id: file.id).pluck(:id).first
      end
      if form_id
        file.assign_attributes(parent_id: form_id)
        file.save(validate: false)
      end
    end
  end

  desc "Generate HPC Patient Referrals for development/staging"
  task dev_create_patient_referrals: [:environment, "log:info_to_stdout"] do
    return if Rails.env.production?
    require 'faker'
    20.times do
      patient = Health::PatientReferral.new
      patient.first_name = Faker::Name.first_name
      patient.last_name = Faker::Name.last_name
      patient.ssn = Faker::IDNumber.valid.gsub('-','')
      patient.birthdate = Faker::Date.birthday(18, 75)
      patient.medicaid_id = Faker::Number.number(12)
      patient.save!
    end
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
          # klass.delete_all
        end
        Health::Claims::Base.known_sub_classes.each do |klass|
          # klass.delete_all
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

    namespace :migrate do
      task :redo do
        Rake::Task["db:migrate:redo"].invoke
      end
      task :up do
        Rake::Task["db:migrate:up"].invoke
      end
      task :down do
        Rake::Task["db:migrate:down"].invoke
      end
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
