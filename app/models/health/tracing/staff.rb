###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
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
      yes_no_unknown_options
    end

    def symptom_options
      {
        'Coughing' => 'Coughing',
        'Fever' => 'Fever',
        'Shortness of breath' => 'Shortness of breath',
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

    def yes_no_unknown_options
      {
        'Unknown' => '',
        'No' => 'No',
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

    def vaccination_date_count
      3
    end

    def to_h
      {
        investigator: investigator,
        date_interviewed: date_interviewed,
        index_case_id: case_id.to_s,
        first_name: first_name,
        last_name: last_name,
        dob_or_age: [dob&.strftime('%m/%d/%Y'), estimated_age].reject(&:blank?)&.join(' / '),
        gender: ::HUD.gender(gender),
        address: address,
        phone_number: phone_number,
        site: site_name,
        contact_notified: notified,
        exposure_nature: nature_of_exposure,
        symptomatic: symptomatic,
        symptoms: ((symptoms || []) + [other_symptoms]).reject(&:blank?).join('/'),
        referred_for_testing: referred_for_testing,
        test_result: test_result,
        vaccinated: vaccinated,
        vaccine: vaccine&.reject(&:blank?)&.join(', '),
        vaccination_dates: vaccination_dates&.map { |v| v&.to_date&.strftime('%m/%d/%Y') }&.compact&.join(', '),
        vaccination_complete: vaccination_complete,
        notes: notes,
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
        vaccinated: 'Vaccinated?',
        vaccine: 'Vaccine(s) received',
        vaccination_dates: 'Dates of vaccinations',
        vaccination_complete: 'Vaccination complete?',
        notes: '',
      }
      @label_for[column_name]
    end

    def self.staff_contacts_columns
      {
        investigator: {
          section_header: 'INVESTIGATION INFO',
          column_header: 'Investigator',
        },
        date_interviewed: {
          section_header: '',
          column_header: 'Date interviewed',
        },
        index_case_id: {
          section_header: '',
          column_header: 'Linked Index Case ID',
        },
        first_name: {
          section_header: 'STAFF CONTACT INFORMATION',
          column_header: 'First Name',
        },
        last_name: {
          section_header: '',
          column_header: 'Last Name',
        },
        dob_or_age: {
          section_header: '',
          column_header: 'DOB or Estimated Age',
        },
        gender: {
          section_header: '',
          column_header: 'Gender',
        },
        address: {
          section_header: '',
          column_header: 'Address if Known',
        },
        phone_number: {
          section_header: '',
          column_header: 'Phone Number',
        },
        site: {
          section_header: '',
          column_header: 'Site',
        },
        contact_notifies: {
          section_header: '',
          column_header: 'Contact Notified',
        },
        exposure_nature: {
          section_header: '',
          column_header: 'Nature of Exposure (frequency, duration, timing)',
        },
        symptomatic: {
          section_header: '',
          column_header: 'Symptomatic?',
        },
        symptoms: {
          section_header: '',
          column_header: 'Symptoms',
        },
        referred_for_testing: {
          section_header: '',
          column_header: 'Referred for testing?',
        },
        test_result: {
          section_header: '',
          column_header: 'Test result',
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
