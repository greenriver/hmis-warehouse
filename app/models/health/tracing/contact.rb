###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: ?
# Control: PHI attributes NOT documented
module Health::Tracing
  class Contact < HealthBase
    acts_as_paranoid
    has_paper_trail

    belongs_to :case
    has_many :locations
    has_many :results

    def alert_options
      {
        'Blank' => '',
        'Active' => 'Active',
        'Removed' => 'Removed',
      }
    end

    def symptomatic_options
      {
        'No' => '',
        'Yes' => 'Yes',
      }
    end

    def symptom_options
      {
        'Coughing' => 'Coughing',
        'Fever' => 'Fever',
        'Shortness of breath' => 'Shortness of breath',
      }
    end

    def referred_options
      {
        'No' => '',
        'Yes' => 'Yes',
      }
    end

    def yes_no_unknown_options
      {
        'Unknown' => '',
        'No' => 'No',
        'Yes' => 'Yes',
      }
    end

    def yes_no_options
      {
        'No' => '',
        'Yes' => 'Yes',
      }
    end

    def vaccination_date_count
      3
    end

    def to_h
      {
        investigator: investigator,
        contact_interviewed: date_interviewed&.strftime('%m/%d/%Y'),
        alert_in_epic: alert_in_epic,
        index_case_id: case_id.to_s,
        first_name: first_name,
        last_name: last_name,
        alias: aliases,
        phone_number: phone_number,
        address: address,
        contact_notified: notified,
        dob_or_age: [dob&.strftime('%m/%d/%Y'), estimated_age].reject(&:blank?)&.join(' / '),
        gender: ::HUD.gender(gender),
        race: race&.reject(&:blank?)&.map { |r| ::HUD.race(r) }&.join(', '),
        ethnicity: ::HUD.ethnicity(ethnicity),
        preferred_language: preferred_language,
        relationship: relationship_to_index_case,
        exposure_location: location_of_exposure,
        exposure_nature: nature_of_exposure,
        location: location_of_contact,
        sleeping_location: sleeping_location,
        symptomatic: symptomatic,
        symptoms: ((symptoms || []) + [other_symptoms]).reject(&:blank?).join('/'),
        symptom_onset_date: symptom_onset_date&.strftime('%m/%d/%Y'),
        referred_for_testing: referred_for_testing,
        test_result_1: results[0]&.test_result,
        isolation_1: results[0]&.isolated,
        isolation_location_1: results[0]&.isolation_location,
        quarantine_1: results[0]&.quarantine,
        quarantine_location_1: results[0]&.quarantine_location,
        test_result_2: results[1]&.test_result,
        isolation_2: results[1]&.isolated,
        isolation_location_2: results[1]&.isolation_location,
        quarantine_2: results[1]&.quarantine,
        quarantine_location_2: results[1]&.quarantine_location,
        test_result_3: results[2]&.test_result,
        isolation_3: results[2]&.isolated,
        isolation_location_3: results[2]&.isolation_location,
        quarantine_3: results[2]&.quarantine,
        quarantine_location_3: results[2]&.quarantine_location,
        test_result_4: results[3]&.test_result,
        isolation_4: results[3]&.isolated,
        isolation_location_4: results[3]&.isolation_location,
        quarantine_4: results[3]&.quarantine,
        quarantine_location_4: results[3]&.quarantine_location,
        vaccinated: vaccinated,
        vaccine: vaccine&.reject(&:blank?)&.join(', '),
        vaccination_dates: vaccination_dates&.map { |v| v.to_date.strftime('%m/%d/%Y') }&.join(', '),
        vaccination_complete: vaccination_complete,
        notes: notes,
      }
    end

    def self.label_for(column_name)
      @label_for ||= {
        investigator: 'Investigator name',
        date_interviewed: 'Date interviewed',
        alert_in_epic: 'Alert in EPIC?',
        first_name: 'First name',
        last_name: 'Last name',
        aliases: 'Aliases',
        phone_number: 'Phone Number',
        address: 'Address (if known)',
        notified: 'Contact notified?',
        dob: 'DOB',
        estimated_age: 'Estimated age',
        gender: 'Gender',
        race: 'Race',
        ethnicity: 'Ethnicity',
        preferred_language: 'Preferred language',
        relationship_to_index_case: 'Relationship to index case',
        location_of_exposure: 'Location of exposure',
        nature_of_exposure: 'Nature of exposure',
        location_of_contact: 'Location where contact may be found',
        sleeping_location: 'Sleeping Location',
        symptomatic: 'Symptomatic?',
        symptom_onset_date: 'Sympton onset date',
        referred_for_testing: 'Referred for testing?',
        test_result: 'Test result',
        isolated: 'Went to Isolation?',
        isolation_location: 'Isolation location',
        quarantine: 'Went to Quarantine?',
        quarantine_location: 'Quarantine location',
        vaccinated: 'Vaccinated?',
        vaccine: 'Vaccine(s) received',
        vaccination_dates: 'Dates of vaccination',
        vaccination_complete: 'Vaccination complete?',
        notes: 'Notes',
      }
      @label_for[column_name]
    end

    def self.patient_contact_columns
      {
        investigator: {
          section_header: 'INVESTIGATION INFO',
          column_header: 'Investigator',
        },
        contact_interviewed: {
          section_header: '',
          column_header: 'Date contact interviewed',
        },
        alert_in_epic: {
          section_header: '',
          column_header: 'Alert in Epic?',
        },
        index_case_id: {
          section_header: '',
          column_header: 'Linked Index Case ID',
        },
        first_name: {
          section_header: 'CONTACT INFORMATION',
          column_header: 'First Name',
        },
        last_name: {
          section_header: '',
          column_header: 'Last Name',
        },
        alias: {
          section_header: '',
          column_header: 'Alias',
        },
        phone_number: {
          section_header: '',
          column_header: 'Phone #',
        },
        address: {
          section_header: '',
          column_header: 'Address if known',
        },
        contact_notified: {
          section_header: '',
          column_header: 'Contact Notified',
        },
        dob_or_age: {
          section_header: '',
          column_header: 'DOB or Estimated Age',
        },
        gender: {
          section_header: '',
          column_header: 'Gender',
        },
        race: {
          section_header: '',
          column_header: 'Race',
        },
        ethnicity: {
          section_header: '',
          column_header: 'Ethnicity',
        },
        preferred_language: {
          section_header: '',
          column_header: 'Preferred Language',
        },
        relationship: {
          section_header: '',
          column_header: 'Relationship to index case',
        },
        exposure_location: {
          section_header: '',
          column_header: 'Location of Exposure',
        },
        exposure_nature: {
          section_header: '',
          column_header: 'Nature of Exposure (frequency, duration, timing)',
        },
        location: {
          section_header: '',
          column_header: 'Location where contact may be found',
        },
        sleeping_location: {
          section_header: '',
          column_header: 'Where person sleeps',
        },
        symptomatic: {
          section_header: '',
          column_header: 'Symptomatic?',
        },
        symptoms: {
          section_header: '',
          column_header: 'Symptoms',
        },
        onset_date: {
          section_header: '',
          column_header: 'Symptom Onset date',
        },
        referred_for_testing: {
          section_header: '',
          column_header: 'Referred for testing?',
        },
        test_result_1: {
          section_header: '',
          column_header: 'Test result 1',
        },
        isolation_1: {
          section_header: '',
          column_header: 'Went to Isolation?',
        },
        isolation_location_1: {
          section_header: '',
          column_header: 'Isolation Location',
        },
        quarantine_1: {
          section_header: '',
          column_header: 'Went to Quarantine?',
        },
        quarantine_location_1: {
          section_header: '',
          column_header: 'Quarantine Location',
        },
        test_result_2: {
          section_header: '',
          column_header: 'Test result 2',
        },
        isolation_2: {
          section_header: '',
          column_header: 'Went to Isolation?',
        },
        isolation_location_2: {
          section_header: '',
          column_header: 'Isolation Location',
        },
        quarantine_2: {
          section_header: '',
          column_header: 'Went to Quarantine?',
        },
        quarantine_location_2: {
          section_header: '',
          column_header: 'Quarantine Location',
        },
        test_result_3: {
          section_header: '',
          column_header: 'Test result 3',
        },
        isolation_3: {
          section_header: '',
          column_header: 'Went to Isolation?',
        },
        isolation_location_3: {
          section_header: '',
          column_header: 'Isolation Location',
        },
        quarantine_3: {
          section_header: '',
          column_header: 'Went to Quarantine?',
        },
        quarantine_location_3: {
          section_header: '',
          column_header: 'Quarantine Location',
        },
        test_result_4: {
          section_header: '',
          column_header: 'Test result 4',
        },
        isolation_4: {
          section_header: '',
          column_header: 'Went to Isolation?',
        },
        isolation_location_4: {
          section_header: '',
          column_header: 'Isolation Location',
        },
        quarantine_4: {
          section_header: '',
          column_header: 'Went to Quarantine?',
        },
        quarantine_location_4: {
          section_header: '',
          column_header: 'Quarantine Location',
        },
        vaccinated: {
          section_header: '',
          column_header: 'Vaccinated?',
        },
        vaccine: {
          section_header: '',
          column_header: 'Vaccine(s) received',
        },
        vaccination_dates: {
          section_header: '',
          column_header: 'Dates of vaccinations',
        },
        vaccination_complete: {
          section_header: '',
          column_header: 'Vaccination complete?',
        },
        notes: {
          section_header: '',
          column_header: 'Notes about this contact:',
        },
      }.freeze
    end

    def label_for(column_name)
      self.class.label_for(column_name)
    end

    def name
      "#{first_name} #{last_name}"
    end
  end
end
