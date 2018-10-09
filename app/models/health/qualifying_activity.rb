module Health
  class QualifyingActivity < HealthBase
    include ArelHelper

    MODE_OF_CONTACT_OTHER = 'other'
    REACHED_CLIENT_OTHER = 'collateral'

    scope :submitted, -> {where.not(claim_submitted_on: nil)}
    scope :unsubmitted, -> {where(claim_submitted_on: nil)}
    scope :submittable, -> do
      where.not(
        mode_of_contact: nil,
        reached_client: nil,
        activity: nil,
        follow_up: nil
      )
    end

    scope :in_range, -> (range) { where(date_of_activity: range)}

    scope :direct_contact, -> do
      where(reached_client: :yes)
    end

    scope :face_to_face, -> do
      where(mode_of_contact: :in_person)
    end

    scope :payable, -> do
      where(hqa_t[:naturally_payable].eq(true).or(hqa_t[:force_payable].eq(true)))
    end

    scope :unpayable, -> do
      where(naturally_payable: false, force_payable: false)
    end

    scope :duplicate, -> do
      where.not(duplicate_id: nil)
    end

    scope :valid_unpayable, -> do
      where(reached_client: :no, mode_of_contact: [:phone_call, :video_call])
    end

    scope :not_valid_unpayable, -> do
      where.not(reached_client: :no, mode_of_contact: [:phone_call, :video_call])
    end

    belongs_to :source, polymorphic: true
    belongs_to :epic_source, polymorphic: true
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
        med_rec: {
          title: 'Supported Medication Reconciliation (NCM only)',
          code: 'G8427',
          weight: 21,
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
          code: 'G9007>U5',
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
          code: 'T1023>U6',
          weight: 90,
        },
        pctp_signed: {
          title: 'Person-Centered Treatment Plan signed',
          code: 'T2024>U4',
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
      face_to_face_modes.include?(value&.to_sym)
    end

    # Return the string and the key so we can check either
    def self.face_to_face_modes
      keys = [
        :in_person,
      ]
      Health::QualifyingActivity.modes_of_contact.select{ |k,_| keys.include? k }.
        map{ |_,m| m[:title] } + keys
    end

    # These validations must come after the above methods
    validates :mode_of_contact, inclusion: {in: Health::QualifyingActivity.modes_of_contact.keys.map(&:to_s)}, allow_blank: true
    validates :reached_client, inclusion: {in: Health::QualifyingActivity.client_reached.keys.map(&:to_s)}, allow_blank: true
    validates :activity, inclusion: {in: Health::QualifyingActivity.activities.keys.map(&:to_s)}, allow_blank: true
    validates_presence_of(
      :user,
      :user_full_name,
      :source, :follow_up,
      :date_of_activity,
      :patient_id,
      :mode_of_contact,
      :reached_client,
      :activity
    )
    validates_presence_of :mode_of_contact_other, if: :mode_of_contact_is_other?
    validates_presence_of :reached_client_collateral_contact, if: :reached_client_is_collateral_contact?

    def submitted?
      claim_submitted_on.present?
    end

    def unsubmitted?
      !submitted?
    end

    def duplicate?
      duplicate_id.present?
    end

    def empty?
      mode_of_contact.blank? &&
      reached_client.blank? &&
      activity.blank? &&
      claim_submitted_on.blank? &&
      follow_up.blank?
    end

    # rules change, figure out what's currently payable and mark them as such
    # def self.update_naturally_payable!
    #   unsubmitted.each do |qa|
    #     qa.update(naturally_payable: qa.procedure_valid? && qa.meets_restrictions?)
    #   end
    # end

    def self.load_string_collection(collection)
      collection.map{|k, v| [v, k]}
    end

    def self.mode_of_contact_collection
      self.load_string_collection(modes_of_contact.select{ |k,_| k != :other }.map{|k, mode| [k, mode[:title]] })
    end

    def self.reached_client_collection
      self.load_string_collection(client_reached.map{|k, mode| [k, mode[:title]] })
    end

    def self.activity_collection
      suppress_from_view = [:pctp_signed]
      self.load_string_collection(
        activities.reject{|k| suppress_from_view.include?(k)}.
        map{|k, mode| [k, mode[:title]] }
      )
    end

    def activity_title key
      return '' unless key
      self.class.activities[key&.to_sym].try(:[], :title) || key
    end

    def mode_of_contact_title key
      return '' unless key
      self.class.modes_of_contact[key&.to_sym].try(:[], :title) || key
    end

    def client_reached_title key
      return '' unless key
      self.class.client_reached[key&.to_sym].try(:[], :title) || key
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
        self.class.modes_of_contact[mode_of_contact&.to_sym].try(:[], :title)
      end
    end

    def title_for_client_reached
      if reached_client.present?
        self.class.client_reached[reached_client&.to_sym].try(:[], :title)
      end
    end

    def title_for_activity
      if activity.present?
        self.class.activities[activity&.to_sym].try(:[], :title)
      end
    end

    def procedure_code
      # ignore any modifiers
      self.class.activities[activity&.to_sym].try(:[], :code)&.split(' ').try(:[], 0)
    end

    def modifiers
      modifiers = []
      # attach modifiers from activity
      modifiers << self.class.activities[activity&.to_sym].try(:[], :code)&.split(' ').try(:[], 1)
      modifiers << self.class.modes_of_contact[mode_of_contact&.to_sym].try(:[], :code)
      modifiers << self.class.client_reached[reached_client&.to_sym].try(:[], :code)
      return modifiers.reject(&:blank?).compact
    end

    def procedure_valid?
      return false unless date_of_activity.present? && activity.present? && mode_of_contact.present? && reached_client.present?
      procedure_code = self.procedure_code
      modifiers = self.modifiers
      # Some special cases
      return false if modifiers.include?('U2') && modifiers.include?('U3')
      return false if modifiers.include?('U1') && modifiers.include?('HQ')
      if procedure_code.to_s == 'T2024' && modifiers.include?('U4') || procedure_code.to_s == 'T2024>U4'
        procedure_code = 'T2024>U4'
        modifiers = modifiers.uniq - ['U4']
      elsif procedure_code.to_s == 'G9007' && modifiers.include?('U5') || procedure_code.to_s == 'G9007>U5'
        procedure_code = 'G9007>U5'
        modifiers = modifiers.uniq - ['U5']
      elsif procedure_code.to_s == 'T1023' && modifiers.include?('U6') || procedure_code.to_s == 'T1023>U6'
        procedure_code = 'T1023>U6'
        modifiers = modifiers.uniq - ['U6']
      else
        procedure_code = procedure_code&.to_sym
      end
      return false if procedure_code.blank?
      return true if modifiers.empty?

      # Check that all of the modifiers we have occur in the acceptable modifiers
      (modifiers - valid_options[procedure_code]).empty?
    end

    # Check for date restrictions (some QA must be completed within a set date range)
    def meets_date_restrictions?
      return true unless restricted_procedure_codes.include? procedure_code
      if in_first_three_months_procedure_codes.include? procedure_code
        return occurred_prior_to_engagement_date
      end
      return true
    end

    # Check duplicate rules (only first of some types per day is payable)
    def meets_repeat_restrictions?
      if once_per_day_procedure_codes.include? procedure_code
        return first_of_type_for_day_for_patient?
      end

      return true
    end

    def first_of_type_for_day_for_patient?
      same_of_type_for_day_for_patient.minimum(:id) == self.id
    end

    def same_of_type_for_day_for_patient
      self.class.where(
        activity: activity,
        patient_id: patient_id,
        date_of_activity: date_of_activity,
      )
    end

    def first_of_type_for_day_for_patient_not_self
      min_id = same_of_type_for_day_for_patient.minimum(:id)
      return nil if min_id == id
      return min_id
    end

    def calculate_payability!
      # Meets general restrictions
      self.naturally_payable = procedure_valid? && meets_date_restrictions?
      if self.naturally_payable && once_per_day_procedure_codes.include?(procedure_code)
        # Log duplicates for any that aren't the first of type for a type that can't be repeated on the same day
        self.duplicate_id = first_of_type_for_day_for_patient_not_self
      else
        self.duplicate_id = nil
      end
      self.save(validate: false) if self.changed?
    end

    # Some procedure modifier/client_reached combinations are technically valid,
    # but obviously un-payable
    # For example: U3 (phone call) with client_reached "did not reach"
    # Flag these for possibly ignoring in the future
    def valid_unpayable?
      if reached_client == 'no' && ['phone_call', 'video_call'].include?(mode_of_contact)
        return true
      end

      return false
    end

    def validity_class
      if valid_unpayable?
        return 'qa-valid-unpayable'
      elsif procedure_valid?
        return 'qa-valid'
      else
        return 'qa-invalid'
      end
    end

    def procedure_with_modifiers
      ([procedure_code] + modifiers).join('>').to_s
    end

    def any_submitted_of_type_for_day_for_patient?
      same_of_type_for_day_for_patient.submitted.exists?
    end

    def occurred_prior_to_engagement_date
      date_of_activity.present? && patient&.engagement_date.present? && date_of_activity <= patient.engagement_date
    end

    def once_per_day_procedure_codes
      [
        'G0506',
        'T2024',
        'T2024>U4',
        'T1023',
        'T1023>U6',
      ]
    end

    def in_first_three_months_procedure_codes
      [
        'G9011',
      ]
    end

    def restricted_procedure_codes
      once_per_day_procedure_codes + in_first_three_months_procedure_codes
    end

    def valid_options
      @valid_options ||= {
        G9011: [
          'U1',
          'U2',
          'U3',
          'UK',
        ],
        G0506: [
          'U1',
          'U2',
          'UK',
        ],
        T2024: [
          'U1',
          'U2',
          'U3',
          'UK',
        ],
        'T2024>U4' => [
          'U1',
          'U2',
          'UK',
        ],
        G9005: [
          'U1',
          'U2',
          'U3',
          'UK',
        ],
        G9007: [
          'U1',
          'U2',
          'U3',
          'UK',
        ],
        'G9007>U5' => [
          'U1',
          'U2',
        ],
        G8427: [
          'U1',
          'U2',
          'U3',
          'UK',
        ],
        G9006: [
          'U1',
          'U2',
          'HQ',
        ],
        G9004: [
          'U1',
          'U2',
          'U3',
          'UK',
        ],
        T1023: [
          'U1',
          'U2',
          'U3',
        ],
        'T1023>U6' => [
          'U1',
          'U2',
          'U3',
        ],
      }
    end
  end
end
