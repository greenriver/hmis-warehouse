###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: ?
# Control: PHI attributes NOT documented
module Health::Tracing
  class Staff < HealthBase
    acts_as_paranoid
    has_paper_trail

    belongs_to :case

    def symptomatic_options
      {
        'Unknown' => '',
        'No' => 'No',
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
      yes_no_options
    end

    def yes_no_options
      {
        'No' => '',
        'Yes' => 'Yes',
      }
    end

    def test_result_options
      {
        'Unknown' => '',
        'Negative' => 'Negative',
        'Positive' => 'Positive',
      }
    end

    def self.label_for(column_name)
      @label_for ||= {
        investigator: 'Investigator name',
        first_name: 'First name',
        last_name: 'Last name',
        phone: 'Phone number',
        address: 'Address (if known)',
        dob: 'DOB',
        estimated_age: 'Estimated age',
        gender: 'Gender',
        site_name: 'Site name',
        notified: 'Notified?',
        nature_of_exposure: 'Nature of exposure',
        symptomatic: 'Symptomatic?',
        symptoms: 'Symptoms',
        other_symptoms: 'Other Symptoms',
        referred_for_testing: 'Referred for testing?',
        test_result: 'Test result',
        notes: '',
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

