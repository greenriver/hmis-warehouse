###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'roo'
require 'rubyXL'
require 'net/sftp'
module Health::Tasks
  class ImportPatientReferralRefreshes
    include NotifierConfig
    FULL_STRING = 'REFRESHREFERRAL_FULL'

    attr_accessor :directory, :referrals_file
    def initialize(directory: 'var/health/referrals')
      @directory = directory
      @logger = Rails.logger
    end

    def import!
      configs = YAML::load(ERB.new(File.read(Rails.root.join("config","health_sftp.yml"))).result)[Rails.env]
      configs.each do |_, config|
        fetch_files(config)
        load_unprocessed
        if @unprocessed.empty?
          remove_files()
          return
        end
        process_files @unprocessed
      end
      remove_files()
    end

    def process_files files
      @incoming_medicaid_ids = []
      files.each do |file_path|
        local_path = File.join(directory, file_path)
        notify "Processing patient referral refreshes in #{local_path}"
        file = load_file(local_path)
        validate_headers(file, file_path)
        headers = file.row(file.first_row)
        db_headers = Health::PatientReferralRefresh.column_headers.invert.values_at(*headers)

        (2..file.last_row).each do |i|
          row = Hash[db_headers.zip(file.row(i))]

          # send a note, and skip if we found anything other than a new or active referral
          if ! row[:record_status].in?(['A', 'N'])
            notify "Patient Referral Refresh Importer found a record that is not Active or New, please see import_patient_referrals.rb, skipping for now, value: #{row[:record_status]}"
            next
          end
          @incoming_medicaid_ids << row[:medicaid_id]
          patient_referral = Health::PatientReferral.
            where(medicaid_id: row[:medicaid_id]).
            first_or_initialize
          # attempt to find ACO ID
          aco_id = Health::AccountableCareOrganization.active.find_by(mco_pid: row[:aco_mco_pid], mco_sl: row[:aco_mco_sl])&.id
          patient_referral.accountable_care_organization_id = aco_id if aco_id.present?
          # if we have a new row or an update
          # save it
          updated_on = Date.strptime(row[:record_updated_on].to_s, '%Y%m%d')
          if patient_referral.record_updated_on.blank? || updated_on > patient_referral.record_updated_on
            patient_referral.assign_attributes(row)
            # Make sure people are not marked rejected if they are appear on this list
            # and haven't been marked as dis-enrolled
            if patient_referral.disenrollment_date.blank?
              patient_referral.assign_attributes(rejected: false, rejected_reason: :Remove_Removal, removal_acknowledged: false)
            end
            patient_referral.save!
          end
        end
        Health::PatientReferralImport.create(file_name: file_path)
      end
      reject_any_not_included()
    end

    def reject_any_not_included
      existing_medicaid_ids = Health::PatientReferral.not_rejected.distinct.pluck(:medicaid_id)
      newly_rejected = existing_medicaid_ids - @incoming_medicaid_ids
      Health::PatientReferral.not_rejected.where(medicaid_id: newly_rejected).
        update_all(rejected: true, rejected_reason: 9) # Reported_Eligibility_Loss
    end

    # Are there any REFRESH_* files we have not yet processed?
    def load_unprocessed
      @unprocessed = available - processed
    end

    def available
      Dir.glob(
        [
          "#{directory}/*/*#{FULL_STRING}*",
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
      expected_headers = Health::PatientReferralRefresh.column_headers.values.map(&:downcase)
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

    def remove_files
      FileUtils.rmtree(directory)
    end

    def notify msg
      @logger.info msg
      @notifier.ping msg if @send_notifications
    end
  end
end
