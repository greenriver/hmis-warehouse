require 'roo'
require 'net/sftp'
module Health::Tasks
  class ImportPatientReferrals
    FILTER_STRING = 'ASSIGNMENT_FULL'
    attr_accessor :directory, :referrals_file 
    def initialize(directory: 'var/health/referrals')
      @directory = directory
    end

    def import!
      # TODO: fetch via sftp available files
      fetch_files()
      load_unprocessed
      return if @unprocessed.empty?
      @unprocessed.each do |file_path|
        file = load_file(File.join(directory, file_path))
        validate_headers(file, file_path)
        headers = file.row(file.first_row)
        db_headers = Health::PatientReferral.column_headers.invert.values_at(*headers)
        
        (2..file.last_row).each do |i|
          row = Hash[db_headers.zip(file.row(i))]
          patient_referral = Health::PatientReferral.where(medicaid_id: row[:medicaid_id]).
            first_or_initialize
          # if we have a new row or an update
          # save it
          updated_on = Date.strptime(row[:updated_on].to_s, '%Y%m%d')
          if patient_referral.updated_on.blank? || updated_on > patient_referral.updated_on
            patient_referral.assign_attributes(row)
            patient_referral.save!
          end
        end
        Health::PatientReferralImport.create(file_name: file_path)
      end

      # TODO: Delete files from local storage
      remove_files()
    end

    # Are there any ASSIGNMENT_FULL files we have not yet processed?
    def load_unprocessed
      @unprocessed = available - processed
    end

    def available
      Dir.glob("#{directory}/*/*#{FILTER_STRING}*").map{|m| m.gsub(directory, '')}
    end

    def processed
      Health::PatientReferralImport.all.pluck(:file_name)
    end

    def load_file file_path
      Roo::Spreadsheet.open(file_path)
    end

    def validate_headers file, file_path
      headers = file.first.map(&:downcase)
      expected_headers = Health::PatientReferral.column_headers.values.map(&:downcase)
      raise "Unexpected headers in: #{file_path} \n #{headers.inspect} \n Looking for: \n #{expected_headers.inspect}" if headers.sort != expected_headers.sort
    end

    def fetch_files
      configs = YAML::load(ERB.new(File.read(Rails.root.join("config","health_sftp.yml"))).result)[Rails.env]
      configs.each do |_, config|
        
      sftp = Net::SFTP.start(
        @config['host'], 
        @config['username'],
        password: @config['password'],
        # verbose: :debug,
        auth_methods: ['publickey','password']
      )
      sftp.download!(@config['path'], @config['destination'], recursive: true)

      notify "Health data downloaded"
    end

    
  end
end