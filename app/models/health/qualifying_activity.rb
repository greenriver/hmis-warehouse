module Health
  class QualifyingActivity < HealthBase

    MODE_OF_CONTACT = [
      'In Person',
      'Phone call',
      'Email',
      'Video call',
      'Other'
    ]
    MODE_OF_CONTACT_OTHER = 'Other'

    REACHED_CLIENT = [
      'Yes (face to face, phone call answered, response to email)',
      'Group session',
      'Did not reach',
      'Collateral contact - not with client directly'
    ]
    REACHED_CLIENT_OTHER = 'Collateral contact - not with client directly'

    ACTIVITY = [
      'Outreach for enrollment',
      'Care coordination',
      'Care planning',
      'Comprehensive Health Assessment',
      'Follow-up within 3 days of hospital discharge (with client)',
      'Care transitions (working with care team)',
      'Health and wellness coaching',
      'Connection to community and social services',
      'Social services screening completed',
      'Referral to ACO for Flexible Services'
    ]

    scope :submitted, -> {where.not(claim_submitted_on: nil)}
    scope :unsubmitted, -> {where(claim_submitted_on: nil)}

    belongs_to :source, polymorphic: true
    belongs_to :user

    validates :mode_of_contact, inclusion: {in: MODE_OF_CONTACT}, allow_blank: true
    validates :reached_client, inclusion: {in: REACHED_CLIENT}, allow_blank: true
    validates :activity, inclusion: {in: ACTIVITY}, allow_blank: true 
    validates_presence_of :user, :user_full_name, :source, :follow_up, :date_of_activity
    validates_presence_of :mode_of_contact_other, if: :mode_of_contact_is_other?
    validates_presence_of :reached_client_collateral_contact, if: :reached_client_is_collateral_contact?

    def submitted?
      claim_submitted_on.present?
    end

    def unsubmitted?
      !submitted?
    end

    def self.load_string_collection(collection)
      [['None', '']] + collection.map do |c|
        [c, c]
      end
    end

    def self.mode_of_contact_collection
      self.load_string_collection(MODE_OF_CONTACT)
    end

    def self.reached_client_collection
      self.load_string_collection(REACHED_CLIENT)
    end

    def self.activity_collection
      self.load_string_collection(ACTIVITY)
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

  end
end