###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health::Tasks
  class PatientClientMatcher
    include NotifierConfig
    include ObviousClientMatcher

    attr_accessor :send_notifications, :notifier_config

    def run!
      setup_notifier('PatientClientMatcher')
      Rails.logger.info 'Loading unprocessed patients'
      started_at = DateTime.now

      unprocessed.each do |patient|
        match_patient_to_client(patient)
      end
      return unmatched()
    end

    # figure out who doesn't yet have an entry in warehouse clients
    def unprocessed
      @unprocessed ||= hashed(Health::Patient.pilot.unprocessed.pluck(*patient_columns), patient_columns)
    end

    # This is only valid for pilot patients, so this is commented out
    def unmatched
      {
        unmatched: 0, # Health::Patient.pilot.unprocessed.count
      }
    end

    def patient_columns
      [
        :id,
        :first_name,
        :last_name,
        :middle_name,
        :birthdate,
        :ssn,
      ]
    end

    def match_patient_to_client(patient)
      patient_first_name = patient[:first_name].downcase
      patient_last_name = patient[:last_name].downcase
      patient_dob = patient[:birthdate]
      patient_ssn = patient[:ssn]

      all_matches = matching_clients(
        ssn: patient_ssn,
        dob: patient_dob,
        first_name: patient_first_name,
        last_name: patient_last_name,
      )

      obvious_matches = all_matches.uniq.map{|i| i if (all_matches.count(i) > 1)}.compact
      if obvious_matches.any?
        patient_record = Health::Patient.find(patient[:id])
        begin
          patient_record.update(
            client_id: obvious_matches.first[:id],
            updated_at: patient_record.updated_at,
          )
        rescue ActiveRecord::RecordNotUnique => e
          msg = "Unable to match patient, failed with the following error #{e}\n"
          msg += e.full_message

          notify(msg)
          return
        end
      end
    end

    def notify(msg)
      Rails.logger.info msg
      @notifier.ping msg if @send_notifications
    end
  end
end
