###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: Describes a patient and contains PHI
# Control: PHI attributes NOT documented
module Health::Tracing
  class Case < HealthBase
    acts_as_paranoid
    has_paper_trail

    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', optional: true
    has_many :locations
    has_many :contacts
    has_many :site_leaders
    has_many :staffs

    scope :ongoing, -> do
      where.not(complete: 'Yes')
    end

    scope :completed, -> do
      where(complete: 'Yes')
    end

    def alert_options
      {
        'Blank' => '',
        'Active' => 'Active',
        'Removed' => 'Removed',
      }
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

    def symptom_options
      {
        'Coughing' => 'Coughing',
        'Fever' => 'Fever',
        'Shortness of breath' => 'Shortness of breath',
      }
    end

    def vaccination_date_count
      3
    end

    def to_h
      {
        index_case_id: id.to_s,
        investigator: investigator,
        date_listed: date_listed&.strftime('%m/%d/%Y'),
        date_interviewed: date_interviewed&.strftime('%m/%d/%Y'),
        alert_in_epic: alert_in_epic,
        investigation_complete: complete,
        infectious_start_date: infectious_start_date&.strftime('%m/%d/%Y'),
        plus_two_weeks: day_two&.strftime('%m/%d/%Y'),
        symptoms: ((symptoms || []) + [other_symptoms]).reject(&:blank?)&.join('/'),
        testing_date: testing_date&.strftime('%m/%d/%Y'),
        isolation_start_date: isolation_start_date&.strftime('%m/%d/%Y'),
        first_name: first_name,
        last_name: last_name,
        alias: aliases,
        dob: dob&.strftime('%m/%d/%Y'),
        gender: ::HUD.gender(gender),
        race: race&.reject(&:blank?)&.map { |r| ::HUD.race(r) }&.join(', '),
        ethnicity: ::HUD.ethnicity(ethnicity),
        preferred_language: preferred_language,
        where_person_sleeps: locations[0]&.location,
        other_location_1: locations[1]&.location,
        other_location_2: locations[2]&.location,
        other_location_3: locations[3]&.location,
        other_location_4: locations[4]&.location,
        occupation: occupation,
        recent_incarceration: recent_incarceration,
        additional_locations: locations[5..]&.map(&:location)&.join(', '),
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
        date_listed: 'Date listed',
        alert_in_epic: 'Alert in EPIC?',
        complete: 'Investigation complete?',
        date_interviewed: 'Date interviewed',
        infectious_start_date: 'Infectious start date',
        day_two: 'Infectious start date + 14 days',
        symptoms: 'Symptoms',
        other_symptoms: 'Other Symptoms',
        testing_date: 'Testing Date',
        isolation_start_date: 'Isolation start date',
        first_name: 'First name',
        last_name: 'Last name',
        phone: 'Phone',
        aliases: 'Aliases',
        dob: 'DOB',
        gender: 'Gender',
        race: 'Race',
        ethnicity: 'Ethnicity',
        preferred_language: 'Preferred language',
        occupation: 'Occupation (if applicable)/Where do they work',
        recent_incarceration: 'Recent incarceration',
        vaccinated: 'Vaccinated?',
        vaccine: 'Vaccine(s) received',
        vaccination_dates: 'Dates of vaccinations',
        vaccination_complete: 'Vaccination complete?',
        notes: 'Notes',
      }
      @label_for[column_name]
    end

    def self.index_case_columns
      {
        index_case_id: {
          section_header: '',
          column_header: 'Index Case ID',
        },
        investigator: {
          section_header: 'INVESTIGATION INFORMATION',
          column_header: 'Investigator',
        },
        date_listed: {
          section_header: '',
          column_header: 'Date listed',
        },
        date_interviewed: {
          section_header: '',
          column_header: 'Date interviewed',
        },
        alert_in_epic: {
          section_header: '',
          column_header: 'Alert in Epic?',
        },
        investigation_complete: {
          section_header: '',
          column_header: 'Investigation complete?',
        },
        infectious_start_date: {
          section_header: 'PERIOD OF INTEREST',
          column_header: 'Infectious Start Date',
        },
        plus_two_weeks: {
          section_header: '',
          column_header: 'Inf Start Date + 14d',
        },
        symptoms: {
          section_header: '',
          column_header: 'Symptoms',
        },
        testing_date: {
          section_header: '',
          column_header: 'Testing Date',
        },
        isolation_start_date: {
          section_header: '',
          column_header: 'Isolation Start Date',
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
        first_name: {
          section_header: 'INDEX CASE INFORMATION',
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
        dob: {
          section_header: '',
          column_header: 'DOB',
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
        where_person_sleeps: {
          section_header: '',
          column_header: 'Where Person Sleeps',
        },
        other_location_1: {
          section_header: '',
          column_header: 'Other Location 1',
        },
        other_location_2: {
          section_header: '',
          column_header: 'Other Location 2',
        },
        other_location_3: {
          section_header: '',
          column_header: 'Other Location 3',
        },
        other_location_4: {
          section_header: '',
          column_header: 'Other Location 4',
        },
        occupation: {
          section_header: '',
          column_header: 'Occupation (if applicable)/Where do they work',
        },
        recent_incarceration: {
          section_header: '',
          column_header: 'Recent incarceration',
        },
        additional_locations: {
          section_header: '',
          column_header: '[add more location columns here as needed]',
        },
        notes: {
          section_header: '',
          column_header: 'Notes about this case:',
        },
      }.freeze
    end

    def label_for(column_name)
      self.class.label_for(column_name)
    end

    def name
      "#{first_name.presence || 'Unknown'} #{last_name.presence || 'Unknown'}"
    end

    def matching_contacts(first_name, last_name)
      first_name = first_name.downcase
      last_name = last_name.downcase
      contacts.select do |c|
        c.first_name.downcase.starts_with?(first_name) ||
          c.last_name.downcase.starts_with?(last_name) ||
          c.aliases.downcase.include?(first_name) ||
          c.aliases.downcase.include?(last_name)
      end
    end

    def age(date = Date.current)
      GrdaWarehouse::Hud::Client.age(date: date.to_date, dob: dob)
    end
  end
end
