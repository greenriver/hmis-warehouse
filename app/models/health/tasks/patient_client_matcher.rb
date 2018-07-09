module Health::Tasks
  class PatientClientMatcher
    def run!
      Rails.logger.info 'Loading unprocessed patients'
      started_at = DateTime.now

      unprocessed.each do |patient|
        match_patient_to_client(patient) if patient.pilot_patient?
      end
      return unmatched()
    end

    # figure out who doesn't yet have an entry in warehouse clients
    def unprocessed
      @unprocessed ||= hashed(Health::Patient.unprocessed.pluck(*patient_columns), patient_columns)
    end

    def unmatched
      {
        unmatched: Health::Patient.unprocessed.count
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

    def match_patient_to_client patient
      patient_first_name = patient[:first_name].downcase
      patient_last_name = patient[:last_name].downcase
      patient_dob = patient[:birthdate]
      patient_ssn = patient[:ssn]
      ssn_matches = []
      birthdate_matches = []
      name_matches = []
      clients.select do |client|
        ssn_matches << client if check_social(patient_ssn, client[:SSN])
        birthdate_matches << client if check_birthday(patient_dob, client[:DOB])
        name_matches << client if check_name(patient_first_name, patient_last_name, client[:FirstName], client[:LastName])
      end
      all_matches = ssn_matches + birthdate_matches + name_matches
      obvious_matches = all_matches.uniq.map{|i| i if (all_matches.count(i) > 1)}.compact
      if obvious_matches.any?
        patient_record = Health::Patient.find(patient[:id])
        patient_record.update(
          client_id: obvious_matches.first[:id],
          updated_at: patient_record.updated_at
        )
      end
    end

    def clients
      @clients ||= hashed(client_destinations.pluck(*client_columns), client_columns)
    end

    # fetch a list of existing clients from the DND Warehouse DataSource (current destinations)
    def client_destinations
      GrdaWarehouse::Hud::Client.destination
    end

    def client_columns
      [
        :id,
        :FirstName,
        :LastName,
        :MiddleName,
        :SSN,
        :DOB,
      ]
    end

    def hashed(results, columns)
      results.map do |row|
        Hash[columns.zip(row)]
      end
    end

    def check_social patient_ssn, client_ssn
      return false if ! ::HUD.valid_social?(patient_ssn)
      patient_ssn == client_ssn
    end

    def check_birthday patient_dob, client_dob
      return false if patient_dob.blank?
      patient_dob == client_dob
    end

    def check_name patient_first, patient_last, client_first, client_last
      "#{patient_first} #{patient_last}" == "#{client_first.downcase} #{client_last.downcase}"
    end
  end
end