###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'zip'
require 'faker'
require 'csv'
module Health::Exporter
  class HealthExporter
    def initialize(file_path: 'tmp/health_export', patients_scope:)
      @zip_file = "#{file_path}/health_export.zip"
      @file_path = "#{file_path}/#{Time.current.to_f}"
      @patients_scope = patients_scope
      @id_cache = {}
      @faker_cache = {}
    end

    def configuration
      @configuration ||= {
        patients: {
          file_name: 'patients.csv',
          columns: [:id, :id_in_source, :first_name, :last_name, :birthdate, :ssn, :created_at, :updated_at, :medicaid_id,
            :engagement_date, :coverage_level, :coverage_inquiry_date, :aco_name, :previous_aco_name, :invalid_id],
          ids: {
            id: :patient_id,
          },
          model_class: Health::Patient,
          association_id: :id,
        },
        patient_referrals: {
          file_name: 'patient_referrals.csv',
          columns: [:id, :first_name, :last_name, :birthdate, :medicaid_id, :created_at, :updated_at, :rejected,
            :rejected_reason, :patient_id, :enrollment_start_date, :disenrollment_date, :stop_reason_description,
            :pending_disenrollment_date, :contributing, :current],
          ids: {
            id: :patient_referral_id,
            patient_id: :patient_id,
          },
          model_class: Health::PatientReferral,
          association_id: :patient_id,
        },
        ssms: {
          file_name: 'self_sufficiency_matrix_forms.csv',
          columns: [:id, :patient_id, :completed_at, :created_at, :updated_at],
          ids: {
            id: :ssm_id,
            patient_id: :patient_id,
          },
          model_class: Health::SelfSufficiencyMatrixForm,
          association_id: :patient_id,
        },
        participation_forms: {
          file_name: 'participation_forms.csv',
          columns: [:id, :patient_id, :signature_on, :location, :reviewed_at, :reviewer],
          ids: {
            id: :participation_id,
            patient_id: :patient_id,
          },
          model_class: Health::ParticipationForm,
          association_id: :patient_id,
        },
        chas: {
          file_name: 'comprehensive_health_assessments.csv',
          columns: [:id, :patient_id, :status, :created_at, :reviewed_at, :completed_at, :reviewed_at, :reviewer],
          ids: {
            id: :cha_id,
            patient_id: :patient_id,
          },
          model_class: Health::ComprehensiveHealthAssessment,
          association_id: :patient_id,
        },
        careplans: {
          file_name: 'careplans.csv',
          columns: [:id, :patient_id, :created_at, :updated_at, :patient_signed_on, :provider_signed_on, :status],
          ids: {
            id: :careplan_id,
            patient_id: :patient_id,
          },
          model_class: Health::Careplan,
          association_id: :patient_id,
        },
        qas: {
          file_name: 'qualifying_activities.csv',
          columns: [:id, :mode_of_contact, :mode_of_contact_other, :reached_client, :reached_client_collateral_contact,
            :activity, :date_of_activity, :patient_id, :created_at, :updated_at, :naturally_payable, :duplicate_id,
            :valid_unpayable, :procedure_valid],
          ids: {
            id: :qa_id,
            patient_id: :patient_id,
          },
          model_class: Health::QualifyingActivity,
          association_id: :patient_id,
        },
      }.freeze
    end

    def fakers
      @fakers ||= {
        id_in_source: [ Faker::IDNumber, :valid ],
        first_name: [ Faker::Name, :first_name ],
        last_name: [ Faker::Name, :last_name ],
        medicaid_id: [ Faker::Number, :number, {digits: 12} ],
        birthdate: [ Faker::Date, :birthday ],
        completed_at: :keep,
        ssn: [Faker::IDNumber, :valid],
        created_at: :keep,
        updated_at: :keep,
        engagement_date: :keep,
        coverage_level: :keep,
        coverage_inquiry_date: :keep,
        aco_name: [ Faker::Company, :name ],
        previous_aco_name: [ Faker::Company, :name ],
        invalid_id: :keep,
        enrollment_start_date: :keep,
        disenrollment_date: :keep,
        stop_reason_description: :keep,
        pending_disenrollment_date: :keep,
        contributing: :keep,
        current: :keep,
        rejected: :keep,
        rejected_reason: :keep,
        mode_of_contact: :keep,
        mode_of_contact_other: [ Faker::App, :name],
        reached_client: :keep,
        reached_client_collateral_contact: [ Faker::Name, :name ],
        activity: :keep,
        date_of_activity: :keep,
        naturally_payable: :keep,
        duplicate_id: :keep,
        valid_unpayable: :keep,
        procedure_valid: :keep,
        signature_on: :keep,
        location: [ Faker::House, :furniture],
        reviewed_at: :keep,
        reviewer: [ Faker::Name, :name ],
        status: :keep,
        patient_signed_on: :keep,
        provider_signed_on: :keep,
      }.freeze
    end

    def export!
      create_export_directory()
      begin
        configuration.keys.each do |conf_key|
          export_table!(conf_key)
        end

        zip_archive
      ensure
        remove_export_files()
      end
    end

    private

    def create_export_directory
      # make sure the path is clean
      FileUtils.rmtree(@file_path) if File.exists? @file_path
      FileUtils.mkdir_p(@file_path)
    end

    def export_table!(conf_key)
      conf = configuration[conf_key]
      export_scope = conf[:model_class].where(conf[:association_id] => @patients_scope.select(:id))
      file = File.join(@file_path, conf[:file_name])
      CSV.open(file, 'wb', headers: conf[:columns], write_headers: true) do |csv|
        export_scope.find_each do |instance|
          row_hash = instance.slice(conf[:columns])
          csv << clean_row(conf_key, row_hash).values
        end
      end
    end

    def clean_row(conf_key, row_hash)
      conf = configuration[conf_key]
      row_hash.keys.each do |column_name|
        if conf[:ids].include?(column_name.to_sym)
          id_key = conf[:ids][column_name.to_sym]
          @id_cache[id_key] ||= {}
          if @id_cache[id_key][row_hash[column_name]].nil?
            @id_cache[id_key][:sequence] ||= 0
            @id_cache[id_key][:sequence] = @id_cache[id_key][:sequence] += 1
            @id_cache[id_key][row_hash[column_name]] = @id_cache[id_key][:sequence]
          end
          row_hash[column_name] = @id_cache[id_key][row_hash[column_name]]
        else
          next if [row_hash[column_name]].blank? # Preserve blanks

          faker = fakers[column_name.to_sym]
          next if faker == :keep

          @faker_cache[column_name] ||= {}
          if @faker_cache[column_name][row_hash[column_name]].nil?
            if faker.size == 3
              value = faker.first.method(faker.second).call(faker.last)
            else
              value = faker.first.method(faker.last).call
            end
            @faker_cache[column_name][row_hash[column_name]] = value
          end
          row_hash[column_name] = @faker_cache[column_name][row_hash[column_name]]
        end
      end
      row_hash
    end

    def zip_archive
      files = Dir.glob(File.join(@file_path, '*')).map{|f| File.basename(f)}
      Zip::File.open(@zip_file, Zip::File::CREATE) do |zipfile|
        files.each do |filename|
          zipfile.add(
            filename,
            File.join(@file_path, filename)
          )
        end
      end
    end

    def remove_export_files
      FileUtils.rmtree(@file_path) if File.exists? @file_path
    end
  end
end
