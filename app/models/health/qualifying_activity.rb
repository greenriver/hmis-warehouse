module Health
  class QualifyingActivity < HealthBase

    MODE_OF_CONTACT = {
      'In Person' => 'U2',
      'Phone call' => 'U3',
      'Email' => 'U3',
      'Video call' => 'U3',
      'Other' => '',
    }
    MODE_OF_CONTACT_OTHER = 'Other'

    REACHED_CLIENT = {
      'Yes (face to face, phone call answered, response to email)' => 'U1',
      'Group session' => 'HQ',
      'Did not reach' => '',
      'Collateral contact - not with client directly' => 'UK',
    }
    REACHED_CLIENT_OTHER = 'Collateral contact - not with client directly'

    ACTIVITY = {
      'Outreach for enrollment' => 'G9011',
      'Care coordination' => 'G9005',
      'Care planning' => 'T2024',
      'Comprehensive Health Assessment' => 'G0506',
      'Follow-up within 3 days of hospital discharge (with client)' => 'G9007 U5',
      'Care transitions (working with care team)' => 'G9007',
      'Health and wellness coaching' => 'G9006',
      'Connection to community and social services' => 'G9004',
      'Social services screening completed' => 'T1023',
      'Referral to ACO for Flexible Services' => 'T1023 U6',
    }

    scope :submitted, -> {where.not(claim_submitted_on: nil)}
    scope :unsubmitted, -> {where(claim_submitted_on: nil)}

    belongs_to :source, polymorphic: true
    belongs_to :user
    belongs_to :patient

    validates :mode_of_contact, inclusion: {in: MODE_OF_CONTACT.keys}, allow_blank: true
    validates :reached_client, inclusion: {in: REACHED_CLIENT.keys}, allow_blank: true
    validates :activity, inclusion: {in: ACTIVITY.keys}, allow_blank: true 
    validates_presence_of :user, :user_full_name, :source, :follow_up, :date_of_activity, :patient_id
    validates_presence_of :mode_of_contact_other, if: :mode_of_contact_is_other?
    validates_presence_of :reached_client_collateral_contact, if: :reached_client_is_collateral_contact?

    def submitted?
      claim_submitted_on.present?
    end

    def unsubmitted?
      !submitted?
    end

    def empty?
      mode_of_contact.blank? && 
      reached_client.blank? && 
      activity.blank? && 
      claim_submitted_on.blank? && 
      date_of_activity.blank? && 
      follow_up.blank?
    end

    def self.load_string_collection(collection)
      [['None', '']] + collection.map do |c|
        [c, c]
      end
    end

    def self.mode_of_contact_collection
      self.load_string_collection(MODE_OF_CONTACT.keys)
    end

    def self.reached_client_collection
      self.load_string_collection(REACHED_CLIENT.keys)
    end

    def self.activity_collection
      self.load_string_collection(ACTIVITY.keys)
    end

    def mode_of_contact_is_other?
      mode_of_contact == MODE_OF_CONTACT_OTHER
    end

    def mode_of_contact_other_value
      MODE_OF_CONTACT_OTHER
    end

    def reached_client_is_collateral_contact?
      reached_client == REACHED_CLIENT_OTHER
    end

    def reached_client_collateral_contact_value
      REACHED_CLIENT_OTHER
    end

    def display_sections(index)
      section = {
        subtitle: "Qualifying Activity ##{index+1}",
        values: [
          {key: 'Mode of Contact:', value: mode_of_contact, other: (mode_of_contact_is_other? ? {key: 'Other:', value: mode_of_contact_other} : false)},
          {key: 'Reached Client:', value: reached_client, other: (reached_client_is_collateral_contact? ? {key: 'Collateral Contact:', value: reached_client_collateral_contact} : false)},
          {key: 'Which type of activity took place?', value: activity, include_br_before: true},
          {key: 'Date of Activity:', value: date_of_activity&.strftime('%b %d, %Y')},
          {key: 'Follow up:', value: follow_up}
        ]
      }
      if claim_submitted_on.present?
        section[:values].push({key: 'Claim submitted on:', value: claim_submitted_on.strftime('%b %d, %Y')})
      end
      section
    end

    def procedure_code
      # ignore any modifiers
      ACTIVITY[activity].split(' ')[0]
    end

    def modifiers
      modifiers = []
      # attach modifiers from activity
      modifiers << ACTIVITY[activity].split(' ')[1]
      modifiers << MODE_OF_CONTACT[mode_of_contact] 
      modifiers << REACHED_CLIENT[reached_client]
      return modifiers.reject(&:blank?).compact
    end
  end
end