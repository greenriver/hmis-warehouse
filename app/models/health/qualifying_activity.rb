module Health
  class QualifyingActivity < HealthBase

    MODE_OF_CONTACT_OTHER = 'other'
    REACHED_CLIENT_OTHER = 'collateral'

    scope :submitted, -> {where.not(claim_submitted_on: nil)}
    scope :unsubmitted, -> {where(claim_submitted_on: nil)}

    scope :in_range, -> (range) { where(date_of_activity: range)}

    scope :direct_contact, -> do
      yes = client_reached[:yes][:title]
      where(reached_client: yes)
    end

    scope :face_to_face, -> do
      where(mode_of_contact: face_to_face_modes)
    end

    belongs_to :source, polymorphic: true
    belongs_to :user
    belongs_to :patient

    def self.modes_of_contact
      @modes_of_contact ||= {
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
      }.sort_by{|_, m| m[:weight]}.to_h
    end

    def self.client_reached
      @client_reached ||= {
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
        collateral: {
          title: 'Collateral contact - not with client directly',
          code: 'UK',
          weight: 30,
        },
      }.sort_by{|_, m| m[:weight]}.to_h
    end

    def self.activities
      @activities ||= {
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
      }.sort_by{|_, m| m[:weight]}.to_h
    end

    def self.date_search(start_date, end_date)
      if start_date.present? && end_date.present?
        self.where("date_of_activity >= ? AND date_of_activity <= ?", start_date, end_date)
      elsif start_date.present?
        self.where("date_of_activity >= ?", start_date)
      elsif end_date.present?
        self.where("date_of_activity <= ?", end_date)
      else
        QualifyingActivity.all
      end
    end

    def self.face_to_face? value
      face_to_face_modes.include?(value)
    end

    def self.face_to_face_modes
      keys = [
        :in_person,
      ]
      Health::QualifyingActivity.modes_of_contact.select{ |k,_| keys.include? k }.
        map{ |_,m| m[:title] }
    end

    # These validations must come after the above methods
    validates :mode_of_contact, inclusion: {in: Health::QualifyingActivity.modes_of_contact.keys.map(&:to_s)}, allow_blank: true
    validates :reached_client, inclusion: {in: Health::QualifyingActivity.client_reached.keys.map(&:to_s)}, allow_blank: true
    validates :activity, inclusion: {in: Health::QualifyingActivity.activities.keys.map(&:to_s)}, allow_blank: true
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
      follow_up.blank?
    end

    def self.load_string_collection(collection)
      [['None', '']] + collection.map do |k, v|
        [v, k]
      end
    end

    def self.mode_of_contact_collection
      self.load_string_collection(modes_of_contact.map{|k, mode| [k, mode[:title]] })
    end

    def self.reached_client_collection
      self.load_string_collection(client_reached.map{|k, mode| [k, mode[:title]] })
    end

    def self.activity_collection
      self.load_string_collection(activities.map{|k, mode| [k, mode[:title]] })
    end

    def activity_title key
      self.class.activities[key.to_sym].try(:[], :title) || key
    end

    def mode_of_contact_title key
      self.class.modes_of_contact[key.to_sym].try(:[], :title) || key
    end

    def client_reached_title key
      self.class.client_reached[key.to_sym].try(:[], :title) || key
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
          {key: 'Mode of Contact:', value: title_for_mode_of_contact, other: (mode_of_contact_is_other? ? {key: 'Other:', value: mode_of_contact_other} : false)},
          {key: 'Reached Client:', value: title_for_client_reached, other: (reached_client_is_collateral_contact? ? {key: 'Collateral Contact:', value: reached_client_collateral_contact} : false)},
          {key: 'Which type of activity took place?', value: title_for_activity, include_br_before: true},
          {key: 'Date of Activity:', value: date_of_activity&.strftime('%b %d, %Y')},
          {key: 'Follow up:', value: follow_up, text_area: true}
        ]
      }
      if claim_submitted_on.present?
        section[:values].push({key: 'Claim submitted on:', value: claim_submitted_on.strftime('%b %d, %Y')})
      end
      section
    end

    def title_for_mode_of_contact
      if mode_of_contact.present?
        self.class.modes_of_contact[mode_of_contact.to_sym].try(:[], :title)
      end
    end

    def title_for_client_reached
      if reached_client.present?
        self.class.client_reached[reached_client.to_sym].try(:[], :title)
      end
    end

    def title_for_activity
      if activity.present?
        self.class.activities[activity.to_sym].try(:[], :title)
      end
    end

    def procedure_code
      # ignore any modifiers
      self.class.activities[activity.to_sym].try(:[], :code)&.split(' ').try(:[], 0)
    end

    def modifiers
      modifiers = []
      # attach modifiers from activity
      modifiers << self.class.activities[activity.to_sym].try(:[], :code)&.split(' ').try(:[], 1)
      modifiers << self.class.modes_of_contact[mode_of_contact.to_sym].try(:[], :code)
      modifiers << self.class.client_reached[reached_client.to_sym].try(:[], :code)
      return modifiers.reject(&:blank?).compact
    end

    def procedure_valid?
      false
    end
  end
end
