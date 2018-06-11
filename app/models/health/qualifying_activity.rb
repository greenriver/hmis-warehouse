module Health
  class QualifyingActivity < HealthBase

    MODE_OF_CONTACT = {
      in_person: {
        title: 'In person',
        code: 'U2',
        weight: 0,
      },
      phone_call: {
        title: 'Phone call',
        code: 'U3',
        weight: 10,
      },
      email: {
        title: 'Email',
        code: 'U3',
        weight: 20,
      },
      video_call: {
        title: 'Video call',
        code: 'U3',
        weight: 30,
      },
      other: {
        title: 'Other',
        code: '',
        weight: 40,
      },
    }
    MODE_OF_CONTACT_OTHER = 'Other'

    REACHED_CLIENT = {
      yes: {
        title: 'Yes (face to face, phone call answered, response to email)',
        code: 'U1',
        weight: 0,
      },
      group: {
        title: 'Group session',
        code: 'HQ',
        weight: 10,
      },
      no: {
        title: 'Did not reach',
        code: '',
        weight: 20,
      },
      yes: {
        title: 'Collateral contact - not with client directly',
        code: 'UK',
        weight: 30,
      },
    }
    REACHED_CLIENT_OTHER = 'Collateral contact - not with client directly'

    ACTIVITY = {
      outreach: { 
        title: 'Outreach for enrollment',
        code: 'G9011',
        weight: 0,
      },
      cha: { 
        title: 'Comprehensive Health Assessment',
        code: 'G0506',
        weight: 10,
      },
      care_planning: { 
        title: 'Care planning',
        code: 'T2024',
        weight: 20,
      },
      care_coordination: { 
        title: 'Care coordination',
        code: 'G9005',
        weight: 30,
      },
      care_transitions: { 
        title: 'Care transitions (working with care team)',
        code: 'G9007',
        weight: 40,
      },
      discharge_follow_up: { 
        title: 'Follow-up within 3 days of hospital discharge (with client)',
        code: 'G9007 U5',
        weight: 50,
      },
      health_coaching: { 
        title: 'Health and wellness coaching',
        code: 'G9006',
        weight: 60,
      },
      community_connection: { 
        title: 'Connection to community and social services',
        code: 'G9004',
        weight: 70,
      },
      screening_completed: { 
        title: 'Social services screening completed',
        code: 'T1023',
        weight: 80,
      },
      referral_to_aco: { 
        title: 'Referral to ACO for Flexible Services',
        code: 'T1023 U6',
        weight: 90,
      },
      pctp_signed: { 
        title: 'Person-Centered Treatment Plan signed',
        code: 'T2024 U4',
        weight: 100,
      },
    }

    scope :submitted, -> {where.not(claim_submitted_on: nil)}
    scope :unsubmitted, -> {where(claim_submitted_on: nil)}

    scope :in_range, -> (range) { where(date_of_activity: range)}

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
      [['None', '']] + collection.map do |k, v|
        [v, k]
      end
    end

    def self.mode_of_contact_collection
      self.load_string_collection(MODE_OF_CONTACT.map{|k, mode| [k, mode[:title]] })
    end

    def self.reached_client_collection
      self.load_string_collection(REACHED_CLIENT.map{|k, mode| [k, mode[:title]] })
    end

    def self.activity_collection
      self.load_string_collection(ACTIVITY.map{|k, mode| [k, mode[:title]] })
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