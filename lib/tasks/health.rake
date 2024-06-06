task spec: ["db:test:prepare:health"]

require 'dotenv'
Dotenv.load('.env', '.env.local')

namespace :health do

  desc "Import and match health data"
  task daily: [:environment, "log:info_to_stdout"] do
    ClaimsReporting::Importer.new.nightly! if RailsDrivers.loaded.include?(:claims_reporting)
    Importing::RunHealthImportJob.new.perform
    Health::Tasks::NotifyCareCoordinatorsOfPatientEligibilityProblems.new.notify!
    Health::Tasks::CalculateValidUnpayableQas.new.run!
    Health::StatusDate.new.maintain
    Health::ProcessConsolidatedContactsJob.perform_later
    Health::EdIpVisitImporter.new.daily!
  end

  task hourly: [:environment, "log:info_to_stdout"] do
    user = User.setup_system_user
    Health::DeliverScheduledDocumentsJob.perform_later(user) if Health::DeliverScheduledDocumentsJob.any_to_run?
    Health::SignableDocument.process_unfetched_signed_documents
  end

  desc "Enrollments and Eligibility"
  task enrollments_and_eligibility: [:environment, "log:info_to_stdout"] do
    begin
      Rake::Task['health:queue_eligibility_determination'].invoke
    rescue StandardError => e
      puts e.message
    end
    begin
      Rake::Task['health:queue_retrieve_enrollments'].invoke
    rescue StandardError => e
      puts e.message
    end
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
      patient.ssn = Faker::IdNumber.valid.gsub('-','')
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
    Health::PatientReferral.cleanup_referrals
  end

  desc "Check for lost hellosign signatures"
  task check_hellosign_signatures: [:environment, 'log:info_to_stdout'] do
    client_ids = Health::Careplan.
      where(provider_signed_on: nil).
      joins(:pcp_signature_requests).
      where.not(signature_requests: { completed_at: nil } ).
      joins(:patient).
      pluck(:client_id)

    puts 'no lost signatures found' if client_ids.count.zero?

    client_ids.each do |client_id|
      puts "https://#{ENV['FQDN']}/clients/#{client_id}/health/careplans"
    end
  end

  desc "Identify and optionally remove (call with [destroy]) empty careplans"
  task :cleanup_careplans, [:destroy] => [:environment, 'log:info_to_stdout'] do |task, args|
    empty = [nil, '']
    hcp_t = Health::Careplan.arel_table
    careplans = Health::Careplan.
      where(hcp_t[:initial_date].lt(Date.current - 1.week)).
      where(
        patient_health_problems: empty,
        patient_strengths: empty,
        patient_barriers: empty,
        patient_signed_on: nil,
      )

    if args[:destroy] == 'destroy'
      careplans.destroy_all
    else
      careplans.each do |careplan|
        puts "https://#{ENV['FQDN']}/clients/#{careplan.patient.client_id}/health/careplans/#{careplan.id}/edit"
      end
    end
  end

  desc "Export CHAs in interchange format"
  task :export_chas, [:filename] => [:environment, 'log:info_to_stdout'] do  |task, args|
    job = Health::ChaTools::Export.setup(filename: args[:filename])
    Kiba.run(job)
  end

  desc "Export patient disenrollment demographics"
  task :export_disenrollment_demographics, [:filename, :start_date, :end_date] => [:environment, 'log:info_to_stdout'] do  |task, args|
    start_date = args[:start_date].to_date
    end_date = args[:end_date].to_date
    Health::Tasks::ExportDisenrollmentDemographics.new(filename: args[:filename], start_date: start_date, end_date: end_date).run!
  end

  desc "Copy participation signature dates into releases"
  task move_participant_signatures: [:environment, 'log:info_to_stdout'] do
    Health::Patient.participating.find_each do |patient|
      release = patient.recent_release_form
      next unless release.present?

      participation_date = patient.recent_participation_form&.signature_on
      if participation_date.blank?
        # If we don't have an earlier participation signature, use the one on the release
        participation_date = release.signature_on
      end
      release.update(participation_signature_on: participation_date)
    end
  end

  # DB related, provides health:db:migrate etc.
  namespace :db do |ns|
    namespace :schema do
      desc "Conditionally load the database schema"
      task :conditional_load, [] => [:environment] do |t, args|
        if HealthBase.connection.table_exists?(:schema_migrations)
          puts "Refusing to load the health database schema since there are tables present. This is not an error."
        else
          Rake::Task['db:schema:load:health'].invoke
        end
      end
    end

    namespace :structure do
      desc "Conditionally load the database structure"
      task :conditional_load, [] => [:environment] do |t, args|
        if HealthBase.connection.table_exists?(:schema_migrations)
          puts "Refusing to load the health database structure since there are tables present. This is not an error."
        else
          Rake::Task['db:structure:load:health'].invoke
        end
      end
    end
  end

  desc "Generate data dictionary of health database"
  task generate_data_dict: [:environment] do
    #loading namespace info
    Rails.configuration.eager_load_namespaces.each(&:eager_load!)

    #creating new csv and fill with header
    csv = CSV.open("./data_dict.csv", "w+")
    csv << [:table_name, :model_name, :attribute, :data_type, :phi_class, :description]

    #preload phi_dict
    phi_dict = HealthBase.phi_dictionary

    #iterate through healthbase descendant classes to fill csv with info
    HealthBase.descendants.each do |record|
      #only proceed if exists and is not abstract
      if !record.abstract_class? && record.table_exists?
        #get table_name and model_name
        table_name = record.table_name.to_s
        model_name = record.model_name.to_s

        #check if model in phi dictionary
        if phi_dict.key?(model_name)
          phi_dict_attr = phi_dict[model_name][:attrbutes].index_by(&:name)
        else phi_dict_attr = {}
        end

        record.columns.each do |attribute|
          #get attribute name and type
          attr_name = attribute.name.to_s
          attr_name_sym = attr_name.to_sym
          attr_type = attribute.type.to_s

          #get phi_class and desc if model in phi dictionary
          if phi_dict_attr.key?(attr_name_sym)
            phi_class = phi_dict_attr[attr_name_sym].category.to_s
            description = phi_dict_attr[attr_name_sym].description.to_s
          else
            phi_class = ""
            description = ""
          end

          #fill csv with corresponding information
          csv << [table_name, model_name, attr_name, attr_type, phi_class, description]
        end

        #insert blank line to separate between tables
        csv << []
      end
    end
  end
end
