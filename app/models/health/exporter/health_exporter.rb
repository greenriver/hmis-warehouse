###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

require 'zip'
require 'faker'
require 'csv'
module Health::Exporter
  class HealthExporter
    CONFIGURATION = {
      patients: {
        file_name: 'patients.csv',
        columns: [:id, :id_in_source, :first_name, :last_name, :medicaid_id],
        ids: {
          id: :patient_id,
        },
      },
      patient_referrals: {
        file_name: 'patient_referrals.csv',
        columns: [:id, :first_name, :last_name, :birthdate, :medicaid_id],
        ids: {
          id: :patient_referral_id,
        },
      },
      ssms: {
        file_name: 'self_sufficiency_matrix_forms.csv',
        columns: [:id, :patient_id, :completed_at],
        ids: {
          id: :ssm_id,
          patient_id: :patient_id,
        },
      }
    }

    FAKERS = {
      id_in_source: [ Faker::IDNumber, :valid ],
      first_name: [ Faker::Name, :first_name ],
      last_name: [ Faker::Name, :last_name ],
      medicaid_id: [ Faker::Number, :number, {digits: 12} ],
      birthdate: [ Faker::Date, :birthday ],
      completed_at: :keep,
    }

    def initialize(file_path: 'var/health_export', patients_scope:)
      @zip_file = "#{file_path}/health_export.zip"
      @file_path = "#{file_path}/#{Time.current.to_f}"
      @patients_scope = patients_scope
      @id_cache = {}
      @faker_cache = {}
    end

    def export!
      create_export_directory()
      begin
        export_table!(:patients, @patients_scope)
        export_table!(:patient_referrals, Health::PatientReferral.where(medicaid_id: @patients_scope.select(:medicaid_id)))
        export_table!(:ssms, Health::SelfSufficiencyMatrixForm.where(patient_id: @patients_scope.select(:id)))

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

    def export_table!(conf_key, export_scope)
      conf = CONFIGURATION[conf_key]
      file = File.join(@file_path, conf[:file_name])
      CSV.open(file, 'wb', headers: conf[:columns], write_headers: true) do |csv|
        export_scope.find_each do |instance|
          row_hash = instance.slice(conf[:columns])
          csv << clean_row(conf_key, row_hash).values
        end
      end
    end

    def clean_row(conf_key, row_hash)
      conf = CONFIGURATION[conf_key]
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

          faker = FAKERS[column_name.to_sym]
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