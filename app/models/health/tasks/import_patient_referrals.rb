require 'roo'
require 'rubyXL'
require 'net/sftp'
module Health::Tasks
  class ImportPatientReferrals
    FULL_STRING = 'ASSIGNMENT_FULL'
    SUMMARY_STRING = 'SUMMARY_FULL'
    CHANGE_STRING = 'ASSIGNMENT_CHG'
    SUMMARY_CHANGE_STRING = 'SUMMARY_CHG'
    attr_accessor :directory, :referrals_file
    def initialize(directory: 'var/health/referrals')
      @directory = directory
      @logger = Rails.logger
    end

    # TODO: Add logic for partial files (if they don't include dis-enrollments, this logic should work with some
    # tweaks to how it handles finding the files)
    def import!
      configs = YAML::load(ERB.new(File.read(Rails.root.join("config","health_sftp.yml"))).result)[Rails.env]
      configs.each do |_, config|
        fetch_files(config)
        load_unprocessed
        if @unprocessed.empty?
          remove_files()
          return
        end
        @unprocessed.each do |file_path|
          local_path = File.join(directory, file_path)
          file = load_file(local_path)
          validate_headers(file, file_path)
          headers = file.row(file.first_row)
          db_headers = Health::PatientReferral.column_headers.invert.values_at(*headers)

          (2..file.last_row).each do |i|
            # send a note, and skip if we found anything other than a new or active referral
            # TODO: handle deletions and inactivations
            if ! row[:record_status].in?(['A', 'N'])
              notify 'Patient Referral Importer found a record that is not Active or New, please see import_patient_referrals.rb, skipping for now'
              next
            end
            row = Hash[db_headers.zip(file.row(i))]
            patient_referral = Health::PatientReferral.where(medicaid_id: row[:medicaid_id]).
              first_or_initialize
            # attempt to find ACO ID
            aco_id = Health::AccountableCareOrganization.find_by(mco_pid: row[:aco_mco_pid], mco_sl: row[:aco_mco_sl])&.id
            patient_referral.accountable_care_organization_id = aco_id if aco_id.present?
            # if we have a new row or an update
            # save it
            updated_on = Date.strptime(row[:updated_on].to_s, '%Y%m%d')
            if patient_referral.updated_on.blank? || updated_on > patient_referral.updated_on
              patient_referral.assign_attributes(row)
              patient_referral.save!
            end
          end
          summary_path = update_summary_receipt(local_path, headers.count, file.last_row - 1)
          upload_summary_reciept(summary_path, config)
          Health::PatientReferralImport.create(file_name: file_path)
        end
      end

      remove_files()
    end

    # Are there any ASSIGNMENT_FULL files we have not yet processed?
    def load_unprocessed
      @unprocessed = available - processed
    end

    def available
      Dir.glob(
        [
          "#{directory}/*/*#{FULL_STRING}*",
          "#{directory}/*/*#{CHANGE_STRING}*",
        ]
      ).map{|m| m.gsub(directory, '')}
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

    def fetch_files config
      sftp = sftp_connect(config)

      source_path = File.join(config['path'], 'referrals')
      sftp.download!(source_path, directory, recursive: true)

      notify "Health patient referrals downloaded"
    end

    def sftp_connect config
      Net::SFTP.start(
        config['host'],
        config['username'],
        password: config['password'],
        # verbose: :debug,
        auth_methods: ['publickey','password']
      )
    end

    def update_summary_receipt(local_path, header_count, row_count)
      summary_file_path = local_path.gsub(FULL_STRING, SUMMARY_STRING).gsub(CHANGE_STRING, SUMMARY_CHANGE_STRING)
      receipt_file_path = summary_file_path.gsub('.xlsx', "R.xlsx")
      summary_file = RubyXL::Parser.parse(summary_file_path)
      reply_sheet = 0
      reply_row = 1
      received_row_number_column = 5
      received_column_number_column = 6
      received_timestamp_column = 7
      sheet = summary_file.worksheets[reply_sheet]
      sheet[reply_row][received_row_number_column].change_contents(row_count)
      sheet[reply_row][received_column_number_column].change_contents(header_count)
      sheet[reply_row][received_timestamp_column].change_contents(Date.today.strftime("%Y%m%d"))
      summary_file.write(receipt_file_path)
      return receipt_file_path
    end

    def upload_summary_reciept summary_path, config
      destination_path = File.join(config['path'], *summary_path.split(File::SEPARATOR).last(3))
      sftp = sftp_connect(config)
      sftp.upload!(summary_path, destination_path)

    end

    def remove_files
      FileUtils.rmtree(directory)
    end

    def notify msg
      @logger.info msg
      @notifier.ping msg if @send_notifications
    end
  end
end