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

    belongs_to :patient
    belongs_to :user

    serialize :topics, Array

    def self.topics_collection
      TOPICS
    end

    def self.place_of_contact_collection
      PLACE_OF_CONTACT
    end

    def place_of_contact_is_other?
      place_of_contact == 'Other'
    end

  end
end