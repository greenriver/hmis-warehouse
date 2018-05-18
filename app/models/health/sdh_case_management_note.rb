module Health
  class SdhCaseManagementNote < HealthBase

    TOPICS = [
      'Basic Needs',
      'Behavioral Health',
      'Benefits and income',
      'Education and employment',
      'Housing stabilsation',
      'Legal',
      'Medical',
      'Needs assessment',
      'Obtain housing',
      'Transportation',
      'Vital document'
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
      'Doubling up',
      'Shelter',
      'Street',
      'Transitional Housing / Residential Treatment Program',
      'Motel',
      'Supportive housing',
      'Housing with no supports',
      'Assisted Living / Nursing Home / Rest Home',
      'Unknown',
      'Other'
    ]
    HOUSING_STATUS_OTHER = 'Other'

    CLIENT_ACTION = [
      'Clilent signed participation form and release of information',
      'Client declined to participate in BH CP program',
      'Client wants to switch to a different BH CP'
    ]

    belongs_to :patient
    belongs_to :user

    # has_many :activities, as: :source, class_name: '::Health::QualifyingActivity', foreign_key: 'source_id', inverse_of: :source
    has_many :activities, as: :source, class_name: '::Health::QualifyingActivity', inverse_of: :source, dependent: :destroy

    serialize :topics, Array

    accepts_nested_attributes_for :activities, reject_if: :all_blank

    validates_presence_of :patient_id, :user_id, :title
    # validates_presence_of :place_of_contact_other, if: :place_of_contact_is_other?
    # validates_presence_of :housing_status_other, if: :housing_status_is_other? 
    # validates :total_time_spent_in_minutes, numericality: {greater_than_or_equal_to: 0}, allow_blank: true
    # validates :place_of_contact, inclusion: {in: PLACE_OF_CONTACT}, allow_blank: true
    # validates :housing_status, inclusion: {in: HOUSING_STATUS}, allow_blank: true
    # validates :client_action, inclusion: {in: CLIENT_ACTION}, allow_blank: true

    def self.topics_collection
      TOPICS
    end

    def self.load_string_collection(collection)
      [['None', '']] + collection.map do |c|
        [c, c]
      end
    end

    def self.place_of_contact_collection
      self.load_string_collection(PLACE_OF_CONTACT)
    end

    def self.housing_status_collection
      self.load_string_collection(HOUSING_STATUS)
    end

    def self.client_action_collection
      self.load_string_collection(CLIENT_ACTION)
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

    def display_basic_info_section
      {
        values: [
          {key: 'Name:', value: patient.client.name},
          {key: 'Date Completed:', value: 'TODO'},
          {key: 'Case Worker:', value: user.name}
        ]
      }
    end

    def display_basic_note_section
      {
        values: [
          {key: 'Topic:', value: topics.join(', ')},
          {key: 'Title:', value: title},
          {key: 'Time Spent:', value: (total_time_spent_in_minutes.present? ? "#{total_time_spent_in_minutes} minutes" : '')}
        ]
      }
    end

    def display_additional_questions_section
      {
        title: 'Additional Questions',
        values: [
          {key: 'Place of Contact:', value: place_of_contact, other: (place_of_contact_is_other? ? {key: 'Other:', value: place_of_contact_other} : false)},
          {key: 'Housing Status:', value: housing_status, other: (housing_status_is_other? ? {key: 'Other:', value: housing_status_other} : false )},
          {key: 'Housing Placement Date:', value: housing_placement_date},
          {key: 'Notes from encounter:', value: notes_from_encounter, text_area: true},
          {key: 'Next Steps:', value: next_steps, text_area: true},
          {key: 'Client Phone:', value: client_phone_number}
        ]
      }
    end

  end
end