###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: Relates to a patient and contains PHI
# Control: PHI attributes documented
module Health
  class SdhCaseManagementNote < HealthBase
    phi_patient :patient_id

    phi_attr :user_id, Phi::SmallPopulation
    # phi_attr :topics
    phi_attr :title, Phi::FreeText
    # phi_attr :total_time_spent_in_minutes
    phi_attr :date_of_contact, Phi::Date
    phi_attr :place_of_contact, Phi::Location
    # phi_attr :housing_status
    phi_attr :place_of_contact_other, Phi::FreeText
    phi_attr :housing_status_other, Phi::FreeText
    phi_attr :housing_placement_date, Phi::Date
    # phi_attr :client_action
    phi_attr :notes_from_encounter, Phi::FreeText
    phi_attr :client_phone_number, Phi::Telephone
    phi_attr :completed_on, Phi::Date
    phi_attr :health_file_id, Phi::OtherIdentifier
    phi_attr :client_action_medication_reconciliation_clinician, Phi::OtherIdentifier

    US_PHONE_NUMBERS = /\A(\+1)?\(?(\d{3})\)?\s*-?\s*(\d{3})\s*-?\s*(\d{4})\s*-?\s*\z/

    TOPICS = [
      'Basic needs',
      'Behavioral health',
      'Benefits and income',
      'Education and employment',
      'Housing stabilization',
      'Legal',
      'Medical',
      'Needs assessment',
      'Obtain housing',
      'Transportation',
      'Vital documents'
    ]

    PLACE_OF_CONTACT = [
      "Street",
      "Shelter",
      "Outpatient clinic",
      "Hospital",
      "Client's home",
      "Other"
    ]
    PLACE_OF_CONTACT_OTHER = 'Other'

    HOUSING_STATUS = [
      'Doubling Up',
      'Shelter',
      'Street',
      'Transitional Housing / Residential Treatment Program',
      'Motel',
      'Supportive Housing',
      'Housing with No Supports',
      'Assisted Living / Nursing Home / Rest Home',
      'Unknown',
      'Other'
    ]
    HOUSING_STATUS_OTHER = 'Other'
    HOUSING_STATUS_DATE = ['Supportive Housing', 'Housing with No Supports']

    CLIENT_ACTION = [
      'Client signed participation form and release of information',
      'Client declined to participate in BH CP program',
      'Client wants to switch to a different BH CP',
      'Client declines consent at this time; willing to revisit',
      'Supporting medication reconciliation'
    ]
    CLIENT_ACTION_OTHER = 'Supporting medication reconciliation'

    belongs_to :patient, optional: true
    belongs_to :user, optional: true

    has_one :health_file, class_name: 'Health::SdhCaseManagementNoteFile', foreign_key: :parent_id, dependent: :destroy
    include HealthFiles

    has_many :activities, as: :source, class_name: '::Health::QualifyingActivity', inverse_of: :source, dependent: :destroy

    serialize :topics, Array
    serialize :client_action, Array

    scope :recent, -> { order(updated_at: :desc).limit(1) }
    scope :last_form_created, -> {order(created_at: :desc).limit(1)}
    scope :with_phone, -> { where.not(client_phone_number: nil) }
    scope :with_housing_status, -> do
      where.not(housing_status: [nil, '']).where.not(date_of_contact: nil)
    end
    scope :within_range, -> (range) do
      where(date_of_contact: range)
    end

    accepts_nested_attributes_for :activities, allow_destroy: true
    validates_associated :activities

    validates_presence_of :patient, :user, :title, :date_of_contact
    validates_presence_of :place_of_contact_other, if: :place_of_contact_is_other?, allow_blank: false
    validates_presence_of :housing_status_other, if: :housing_status_is_other?, allow_blank: false
    validates_presence_of :client_action_medication_reconciliation_clinician, if: :client_action_is_medication_reconciliation_clinician?, allow_blank: false
    validates :total_time_spent_in_minutes, numericality: {greater_than_or_equal_to: 0}, allow_blank: true
    validates :place_of_contact, inclusion: {in: PLACE_OF_CONTACT}, allow_blank: true
    validates :housing_status, inclusion: {in: HOUSING_STATUS}, allow_blank: true
    validate :validate_health_file_if_present

    # doing this after validation because form updates with ajax and no validation
    # keep the date around until they hit save
    after_validation :remove_housing_placement_date

    def remove_housing_placement_date
      unless housing_status_includes_date?
        self.housing_placement_date = nil
      end
    end

    def self.last_form
      last_form_created.first
    end

    def submitted_activities
      activities.submitted
    end

    def unsubmitted_activities
      activities.unsubmitted
    end

    def self.topics_collection
      TOPICS
    end

    def self.load_string_collection(collection, include_none: true)
      collection = collection.map{|c| [c, c]}
      if include_none
        [['None', '']] + collection
      else
        collection
      end
    end

    def self.place_of_contact_collection
      self.load_string_collection(PLACE_OF_CONTACT)
    end

    def self.housing_status_collection
      self.load_string_collection(HOUSING_STATUS)
    end

    def self.client_action_collection
      self.load_string_collection(CLIENT_ACTION, include_none: false)
    end

    def place_of_contact_is_other?
      place_of_contact == PLACE_OF_CONTACT_OTHER
    end

    def place_of_contact_other_value
      PLACE_OF_CONTACT_OTHER
    end

    def housing_status_is_other?
      housing_status == HOUSING_STATUS_OTHER
    end

    def housing_status_other_value
      HOUSING_STATUS_OTHER
    end

    def housing_status_includes_date?
      HOUSING_STATUS_DATE.include?(housing_status)
    end

    def housing_status_include_date_values
      HOUSING_STATUS_DATE
    end

    def client_action_is_medication_reconciliation_clinician?
      client_action.include?(CLIENT_ACTION_OTHER)
    end

    def client_action_medication_reconciliation_clinician_value
      CLIENT_ACTION_OTHER
    end

    def user_can_edit?(current_user)
      current_user.id == user_id && current_user.can_edit_patient_items_for_own_agency?
    end

    def display_note_form_sections
      [
        {id: :basic_info, title: 'Note Details'},
        {id: :activities, title: 'Qualifying Activities'},
        {id: :additional_questions, title: 'Additional Questions'}
      ]
    end

    def display_basic_info_section
      {
        values: [
          {key: 'Name:', value: patient.client.name},
          {key: 'Date Completed:', value: completed_on&.to_date},
          {key: 'Case Worker:', value: user.name}
        ]
      }
    end

    def display_basic_note_section
      {
        values: [
          {key: 'Topic:', value: topics.join(', ')},
          {key: 'Title:', value: title},
          {key: 'Time Spent:', value: (total_time_spent_in_minutes.present? ? "#{total_time_spent_in_minutes} minutes" : '')},
          {key: 'Date of contact:', value: date_of_contact&.strftime('%b %d, %Y')}
        ]
      }
    end

    def display_note_details_section
      {
        values: [
          {key: 'Place of Contact:', value: place_of_contact, other: (place_of_contact_is_other? ? {key: 'Other:', value: place_of_contact_other} : false)},
          {key: 'Housing Status:', value: housing_status, other: (housing_status_is_other? ? {key: 'Other:', value: housing_status_other} : false )},
          {key: 'Housing Placement Date:', value: housing_placement_date},
          {key: 'The following happened:', value: client_action, list: true, other: (client_action_is_medication_reconciliation_clinician? ? {key: 'Clinician who performed medication reconciliation:', value: client_action_medication_reconciliation_clinician} : false)},
          {key: 'Client Phone:', value: client_phone_number}
        ]
      }
    end

    def display_additional_questions_section
      {
        title: 'Additional Questions',
        values: [
          {key: 'Additional Information:', value: notes_from_encounter, text_area: true},
          {key: 'File:', value: health_file&.name, download: true},
          {key: 'File Description:', value: health_file&.note, text_area: true}
        ]
      }
    end

    def validate_health_file_if_present
      if health_file.present? && health_file.invalid?
        errors.add :health_file, health_file.errors.messages.try(:[], :file)&.uniq&.join('; ')
      end
    end

    def encounter_report_details
      {
        source: 'Warehouse',
        housing_status: housing_status,
      }
    end
  end
end
