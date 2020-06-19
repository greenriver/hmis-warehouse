###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
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

    scope :ongoing, -> () do
      where.not(complete: 'Yes')
    end

    scope :completed, -> () do
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

    def symptom_options
      {
        'Coughing' => 'Coughing',
        'Fever' => 'Fever',
        'Shortness of breath' => 'Shortness of breath'
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
        notes: 'Notes',
      }
      @label_for[column_name]
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

    def age date=Date.current
      GrdaWarehouse::Hud::Client.age(date: date.to_date, dob: dob)
    end
  end
end
