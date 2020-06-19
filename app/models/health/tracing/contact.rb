###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
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
        'Shortness of breath' => 'Shortness of breath'
      }
    end

    def referred_options
      {
        'No' => '',
        'Yes' => 'Yes',
      }
    end

    def yes_no_options
      {
        'No' => '',
        'Yes' => 'Yes',
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
        notes: 'Notes',
      }
      @label_for[column_name]
    end

    def label_for(column_name)
      self.class.label_for(column_name)
    end

    def name
      "#{first_name} #{last_name}"
    end
  end
end