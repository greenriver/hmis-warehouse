task spec: ["health:db:test:prepare"]

require 'dotenv'
Dotenv.load('.env', '.env.local')

namespace :health do

  desc "Import and match health data"
  task daily: [:environment, "log:info_to_stdout"] do
    Importing::RunHealthImportJob.new.perform
    Health::Tasks::NotifyCareCoordinatorsOfPatientEligibilityProblems.new.notify!
    Health::Tasks::CalculateValidUnpayableQas.new.run!
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

  desc "Queue Eligibility Determination"
  task queue_eligibility_determination: [:environment, "log:info_to_stdout"] do
    date = Date.current
    user = User.setup_system_user
    batch_owner = Health::EligibilityInquiry.create!(service_date: date, has_batch: true)
    Health::CheckPatientEligibilityJob.perform_later(
      eligibility_date: date.to_s,
      owner_id: batch_owner.id,
      user_id: user.id,
    )
  end

  desc "Queue Retrieve Enrollments"
  task queue_retrieve_enrollments: [:environment, "log:info_to_stdout"] do
    user = User.setup_system_user
    Health::UpdatePatientEnrollmentsJob.perform_now(user)
  end

  desc "Remove Derived Patient Referrals"
  task remove_derived_patient_referrals: [:environment, 'log:info_to_stdout'] do
    Health::PatientReferral.where(derived_referral: true).destroy_all
  end

  desc "Compute derived patient referrals"
  task compute_derived_patient_referrals: [:environment, 'log:info_to_stdout'] do
    pending_referrals = []
    Health::PatientReferral.where(derived_referral: false).find_each do |referral|
      pending_referrals << referral.build_derived_referrals
    end
    Health::PatientReferral.transaction do
      # Not using import to ensure that PaperTrail gets run
      pending_referrals.flatten.each(&:save!)
    end
  end

  desc "Clean up referrals"
  task cleanup_referrals: [:environment, 'log:info_to_stdout'] do
    referral_source = Health::PatientReferral.joins(:patient) # Limit to referrals with patients
    h_pr_t = referral_source.arel_table
    cleanup_time = Date.today.to_time

    # Any non-current enrollments should have a disenrollment date
    # Assign the day before the current enrollment start date, if one exists, otherwise leave it, as something else is
    # wrong...
    hanging_enrollments = referral_source.where(current: false, pending_disenrollment_date: nil, disenrollment_date: nil)
    hanging_enrollments.each do |referral|
      disenrollment_date = referral.patient.patient_referral&.enrollment_start_date&.prev_day
      # If the current enrollment is on our start date, then make it an empty enrollment, which will be cleaned up later...
      disenrollment_date = referral.enrollment_start_date if disenrollment_date.present? && disenrollment_date < referral.enrollment_start_date
      referral.update(disenrollment_date: disenrollment_date)
    end

    # An empty referral is one where the enrollment and disenrollment date are the same.
    empty_referrals = referral_source.where(current: false).
      where(
        h_pr_t[:enrollment_start_date].eq(h_pr_t[:disenrollment_date]).
          or(h_pr_t[:enrollment_start_date].eq(h_pr_t[:pending_disenrollment_date]).
            and(h_pr_t[:disenrollment_date].eq(nil))),
      )
    # Remove the empty referrals
    empty_referrals.update_all(deleted_at: cleanup_time)

    # Multiple referrals for a patient that start on the same day
    referral_groups = referral_source.group(:patient_id, h_pr_t[:enrollment_start_date]).count
    referral_groups_with_duplicate_starts = referral_groups.select { |_key, v| v > 1 }

    # Go through each (patient, start date) pair
    referral_groups_with_duplicate_starts.keys.each do |patient_id, enrollment_start_date|
      referrals = referral_source.where(patient_id: patient_id, enrollment_start_date: enrollment_start_date)
      older_referrals = referrals.where(current: false) # The older referrals are not current
      if referrals.count == older_referrals.count
        # All the referrals are older, so, just keep the longest one
        longest_referral = nil
        longest_referral_length = nil
        older_referrals.each do |referral|
          referral_start = referral.enrollment_start_date
          referral_end = referral.disenrollment_date || referral.pending_disenrollment_date # older referrals must have an end
          days = (referral_end - referral_start).to_i
          if longest_referral_length.nil? || days > longest_referral_length
            longest_referral = referral
            longest_referral_length = days
          end
        end
        # Remove all but the longest, and make sure we have a current referral
        referrals.where.not(id: longest_referral.id).update_all(deleted_at: cleanup_time)
        longest_referral.update(current: true) if longest_referral.patient.patient_referral.blank?
      else
        # There is a current referral in the duplicates, remove the older referrals, leaving the current one
        older_referrals.update_all(deleted_at: cleanup_time)
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

      desc "Conditionally load the database schema"
      task :conditional_load, [] => [:environment] do |t, args|
        if HealthBase.connection.tables.length == 0
          Rake::Task['health:db:schema:load'].invoke
        else
          puts "Refusing to load the health database schema since there are tables present. This is not an error."
        end
      end
    end

    namespace :structure do
      task :load do
        Rake::Task["db:structure:load"].invoke
      end

      task :dump do
        Rake::Task["db:structure:dump"].invoke
      end

      desc "Conditionally load the database structure"
      task :conditional_load, [] => [:environment] do |t, args|
        if HealthBase.connection.tables.length == 0
          HealthBase.connection.execute(File.read('db/health/structure.sql'))
        else
          puts "Refusing to load the health database structure since there are tables present. This is not an error."
        end
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

  task set_custom_config: [:environment] do
    HealthBase.setup_config
  end

  task revert_to_original_config: [:environment] do
    ApplicationRecord.setup_config
  end
end
