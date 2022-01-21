###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: Relates to a patient and contains PHI
# Control: PHI attributes documented
module Health
  class QualifyingActivity < HealthBase
    include ArelHelper

    phi_patient :patient_id

    phi_attr :mode_of_contact, Phi::FreeText
    phi_attr :mode_of_contact_other, Phi::FreeText
    phi_attr :reached_client, Phi::FreeText
    phi_attr :reached_client_collateral_contact, Phi::FreeText
    phi_attr :activity, Phi::FreeText
    # phi_attr :source_type
    # phi_attr :source_id
    phi_attr :claim_submitted_on, Phi::Date
    phi_attr :date_of_activity, Phi::Date
    phi_attr :user_id, Phi::OtherIdentifier
    phi_attr :user_full_name, Phi::NeedsReview
    phi_attr :follow_up, Phi::FreeText
    phi_attr :claim_id, Phi::SmallPopulation # belongs_to Health::Claim, optional: true
    # phi_attr :force_payable
    # phi_attr :naturally_payable
    phi_attr :sent_at, Phi::Date
    phi_attr :duplicate_id, Phi::OtherIdentifier
    phi_attr :epic_source_id, Phi::OtherIdentifier

    MODE_OF_CONTACT_OTHER = 'other'.freeze
    REACHED_CLIENT_OTHER = 'collateral'.freeze

    scope :submitted, -> do
      where.not(claim_submitted_on: nil)
    end

    scope :unsubmitted, -> do
      where(claim_submitted_on: nil)
    end

    scope :submittable, -> do
      where.not(
        mode_of_contact: nil,
        reached_client: nil,
        activity: nil,
        follow_up: nil,
      )
    end

    scope :in_range, ->(range) do
      where(date_of_activity: range)
    end

    scope :direct_contact, -> do
      where(reached_client: :yes)
    end

    scope :face_to_face, -> do
      where(mode_of_contact: :in_person)
    end

    scope :payable, -> do
      where(naturally_payable: true).
        or(where(force_payable: true))
    end

    scope :unpayable, -> do
      where(
        naturally_payable: false,
        force_payable: false,
      )
    end

    scope :duplicate, -> do
      where.not(duplicate_id: nil)
    end

    # Some procedure modifier/client_reached combinations are technically valid,
    # but obviously un-payable
    # For example: U3 (phone call) with client_reached "did not reach"
    # or the outreach was outside of the allowable window
    #
    # NOTE: this is computed daily and depends on both the QA import and the referrals
    scope :valid_unpayable, -> do
      where(valid_unpayable: true)
    end

    scope :not_valid_unpayable, -> do
      where(valid_unpayable: false)
    end

    scope :during_current_enrollment, -> do
      where(
        arel_table[:date_of_activity].
        gteq(hpr_t[:enrollment_start_date]).
        and(
          hpr_t[:disenrollment_date].eq(nil).
          or(
            arel_table[:date_of_activity].lteq(hpr_t[:disenrollment_date]),
          ),
        ),
      ).
        joins(patient: :patient_referrals).
        merge(Health::PatientReferral.contributing)
    end

    belongs_to :source, polymorphic: true, optional: true
    belongs_to :epic_source, polymorphic: true, optional: true
    belongs_to :user, optional: true
    belongs_to :patient, optional: true

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
      }.sort_by { |_, m| m[:weight] }.to_h
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
      }.sort_by { |_, m| m[:weight] }.to_h
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
      }.sort_by { |_, m| m[:weight] }.to_h
    end

    def self.date_search(start_date, end_date)
      if start_date.present? && end_date.present?
        where('date_of_activity >= ? AND date_of_activity <= ?', start_date, end_date)
      elsif start_date.present?
        where('date_of_activity >= ?', start_date)
      elsif end_date.present?
        where('date_of_activity <= ?', end_date)
      else
        QualifyingActivity.all
      end
    end

    def self.face_to_face?(value)
      face_to_face_modes.include?(value&.to_sym)
    end

    # Return the string and the key so we can check either
    def self.face_to_face_modes
      keys = [
        :in_person,
      ]
      Health::QualifyingActivity.modes_of_contact.select { |k, _| keys.include? k }.
        map { |_, m| m[:title] } + keys
    end

    # These validations must come after the above methods
    validates :mode_of_contact, inclusion: { in: Health::QualifyingActivity.modes_of_contact.keys.map(&:to_s) }, allow_blank: true
    validates :reached_client, inclusion: { in: Health::QualifyingActivity.client_reached.keys.map(&:to_s) }, allow_blank: true
    validates :activity, inclusion: { in: Health::QualifyingActivity.activities.keys.map(&:to_s) }, allow_blank: true
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

    def self.load_string_collection(collection)
      collection.map { |k, v| [v, k] }
    end

    def self.mode_of_contact_collection
      load_string_collection(
        modes_of_contact.
        # select{ |k,_| k != :other }.
        map { |k, mode| [k, mode[:title]] },
      )
    end

    def self.reached_client_collection
      load_string_collection(
        client_reached.
        map { |k, mode| [k, mode[:title]] },
      )
    end

    def self.activity_collection
      # suppress_from_view = [:pctp_signed]
      load_string_collection(
        activities.
        # reject{|k| suppress_from_view.include?(k)}.
        map { |k, mode| [k, mode[:title]] },
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
        subtitle: "Qualifying Activity ##{index + 1}",
        values: [
          { key: 'Mode of Contact:', value: title_for_mode_of_contact, other: (mode_of_contact_is_other? ? { key: 'Other:', value: mode_of_contact_other } : false) },
          { key: 'Reached Client:', value: title_for_client_reached, other: (reached_client_is_collateral_contact? ? { key: 'Collateral Contact:', value: reached_client_collateral_contact } : false) },
          { key: 'Which type of activity took place?', value: title_for_activity, include_br_before: true },
          { key: 'Date of Activity:', value: date_of_activity&.strftime('%b %d, %Y') },
          { key: 'Follow up:', value: follow_up, text_area: true },
        ],
      }
      section[:values].push({ key: 'Claim submitted on:', value: claim_submitted_on.strftime('%b %d, %Y') }) if claim_submitted_on.present?
      section
    end

    def title_for_mode_of_contact
      self.class.modes_of_contact[mode_of_contact&.to_sym].try(:[], :title) if mode_of_contact.present?
    end

    def title_for_client_reached
      self.class.client_reached[reached_client&.to_sym].try(:[], :title) if reached_client.present?
    end

    def title_for_activity
      self.class.activities[activity&.to_sym].try(:[], :title) if activity.present?
    end

    def procedure_code
      # ignore any modifiers
      self.class.activities[activity&.to_sym].try(:[], :code)&.split(' ').try(:[], 0)
    end

    def outreach?
      activity == 'outreach'
    end

    def modifiers
      modifiers = []
      # attach modifiers from activity
      modifiers << self.class.activities[activity&.to_sym].try(:[], :code)&.split(' ').try(:[], 1)
      modifiers << self.class.modes_of_contact[mode_of_contact&.to_sym].try(:[], :code)
      modifiers << self.class.client_reached[reached_client&.to_sym].try(:[], :code)
      return modifiers.reject(&:blank?).compact
    end

    def compute_procedure_valid?
      return false unless date_of_activity.present? && activity.present? && mode_of_contact.present? && reached_client.present?

      procedure_code = self.procedure_code
      modifiers = self.modifiers
      reached_client = self.reached_client
      # Some special cases
      return false if modifiers.include?('U2') && modifiers.include?('U3') # Marked as both f2f and indirect
      return false if modifiers.include?('U1') && modifiers.include?('HQ') # Marked as both individual and group

      if procedure_code.to_s == 'T2024' && modifiers.include?('U4') || procedure_code.to_s == 'T2024>U4'
        procedure_code = 'T2024>U4'.to_sym
        modifiers = modifiers.uniq - ['U4']
      elsif procedure_code.to_s == 'G9007' && modifiers.include?('U5') || procedure_code.to_s == 'G9007>U5'
        procedure_code = 'G9007>U5'.to_sym
        modifiers = modifiers.uniq - ['U5']
      elsif procedure_code.to_s == 'T1023' && modifiers.include?('U6') || procedure_code.to_s == 'T1023>U6'
        procedure_code = 'T1023>U6'.to_sym
        modifiers = modifiers.uniq - ['U6']
      else
        procedure_code = procedure_code&.to_sym
      end

      # If the client isn't reached, and it's an in-person encounter, you can only count outreach attempts
      if reached_client.to_s == 'no'
        return false if modifiers.uniq.count == 1 && modifiers.include?('U2') && procedure_code.to_s != 'G9011'
      end

      return false if procedure_code.blank?
      return true if modifiers.empty?

      # Check that all of the modifiers we have occur in the acceptable modifiers
      (modifiers - Array.wrap(valid_options[procedure_code])).empty?
    end

    def first_of_type_for_day_for_patient?
      # Assumes ids are strictly increasing, so the lowest id will
      # be the id of the first QA on the day
      same_of_type_for_day_for_patient.minimum(:id) == id
    end

    # Find the id of the first_of_type_for_day_for_patient if is
    # different from this one.
    def first_of_type_for_day_for_patient_not_self
      min_id = same_of_type_for_day_for_patient.minimum(:id)
      return nil if min_id == id

      min_id
    end

    def first_outreach_of_month_for_patient?
      outreaches_of_month_for_patient.
        payable.not_valid_unpayable. # Limit to payable QAs
        or(self.class.where(id: id)). # Assume that we are payable for this calculation
        minimum(:id) == id
    end

    def first_non_outreach_of_month_for_patient?
      non_outreaches_of_month_for_patient.
        payable.not_valid_unpayable. # Limit to payable QAs
        or(self.class.where(id: id)). # Assume that we are payable for this calculation
        minimum(:id) == id
    end

    def number_of_outreach_activity_months
      outreaches_by_month = self.class.where(
        activity: :outreach,
        patient_id: patient_id,
        date_of_activity: patient.contributed_enrollment_ranges,
      ).where(
        hqa_t[:date_of_activity].lteq(date_of_activity),
      ).group(
        Arel.sql("DATE_TRUNC('month', date_of_activity)"),
      ).count
      outreaches_by_month.reject { |_k, v| v.zero? }.keys.count
    end

    def number_of_non_outreach_activity_months
      non_outreaches_by_month = self.class.where(
        patient_id: patient_id,
        date_of_activity: patient.contributed_enrollment_ranges,
      ).where.not(
        activity: :outreach,
      ).where(
        hqa_t[:date_of_activity].lteq(date_of_activity),
      ).group(
        Arel.sql("DATE_TRUNC('month', date_of_activity)"),
      ).count
      non_outreaches_by_month.reject { |_k, v| v.zero? }.keys.count
    end

    def same_of_type_for_day_for_patient
      self.class.where(
        activity: activity,
        patient_id: patient_id,
        date_of_activity: date_of_activity,
      )
    end

    def outreaches_of_month_for_patient
      self.class.where(
        patient_id: patient_id,
        date_of_activity: (date_of_activity.beginning_of_month..date_of_activity.end_of_month),
      ).where(
        activity: :outreach,
      )
    end

    def non_outreaches_of_month_for_patient
      self.class.where(
        patient_id: patient_id,
        date_of_activity: (date_of_activity.beginning_of_month..date_of_activity.end_of_month),
      ).where.not(
        activity: :outreach,
      )
    end

    def calculate_payability!
      # Meets general restrictions
      # 10/31/2018 removed meets_date_restrictions? check.  QA that are valid but unpayable
      # will still be submitted
      self.naturally_payable = compute_procedure_valid?
      if naturally_payable && once_per_day_procedure_codes.include?(procedure_code.to_s)
        # Log duplicates for any that aren't the first of type for a type that can't be repeated on the same day
        self.duplicate_id = first_of_type_for_day_for_patient_not_self
      else
        self.duplicate_id = nil
      end
      save(validate: false) if changed?
    end

    def maintain_cached_values
      calculate_payability!
      maintain_procedure_valid
      maintain_valid_unpayable
    end

    def maintain_valid_unpayable
      self.valid_unpayable_reason = compute_valid_unpayable
      self.valid_unpayable = compute_valid_unpayable?
      save(validate: false)
    end

    def maintain_procedure_valid
      self.procedure_valid = compute_procedure_valid?
      save(validate: false)
    end

    def compute_valid_unpayable?
      compute_valid_unpayable.present?
    end

    # Returns the reason the QA is valid unpayable, or nil
    # :outside_enrollment -
    # :call_not_reached -
    # :outreach_past_cutoff -
    # :limit_outreaches_per_month_exceeded -
    # :limit_months_outreach_exceeded -
    # :limit_activities_per_month_without_careplan_exceeded -
    # :activity_outside_of_engagement_without_careplan -
    # :limit_months_without_careplan_exceeded -
    def compute_valid_unpayable
      @compute_valid_unpayable ||= internal_compute_valid_unpayable
    end

    private def internal_compute_valid_unpayable
      reasons = []
      computed_procedure_valid = compute_procedure_valid?

      # Only valid procedures can be valid unpayable
      return nil unless computed_procedure_valid

      # Unpayable if it is a valid procedure, but it didn't occur during an enrollment
      reasons << :outside_enrollment if computed_procedure_valid && ! occurred_during_any_enrollment?

      # Unpayable if this was a phone/video call where the client wasn't reached
      reasons << :call_not_reached if reached_client == 'no' && ['phone_call', 'video_call'].include?(mode_of_contact)

      # Signing a care plan is payable regardless of engagement status
      return reasons if activity == 'pctp_signed'

      # Outreach is limited by the outreach cut-off date, enrollment ranges, and frequency
      if outreach?
        reasons << :outreach_past_cutoff if date_of_activity > patient.outreach_cutoff_date
        reasons << :outside_enrollment unless patient.contributed_dates.include?(date_of_activity)
        reasons << :limit_outreaches_per_month_exceeded unless first_outreach_of_month_for_patient?
        reasons << :limit_months_outreach_exceeded if number_of_outreach_activity_months > 3
      else
        # Non-outreach activities are payable at 1 per month before engagement unless there is a care-plan
        unless patient_has_signed_careplan?
          reasons << :limit_activities_per_month_without_careplan_exceeded unless first_non_outreach_of_month_for_patient?
          reasons << :activity_outside_of_engagement_without_careplan if patient.engagement_date.blank? || date_of_activity > patient.engagement_date
          reasons << :limit_months_without_careplan_exceeded if number_of_non_outreach_activity_months > 5
        end
      end

      reasons.uniq
    end

    def validity_class
      return 'qa-ignored' if ignored?
      return 'qa-valid-unpayable' if valid_unpayable?
      return 'qa-valid' if procedure_valid?

      'qa-invalid'
    end

    def describe_validity_reasons
      if valid_unpayable?
        return valid_unpayable_reasons.map do |reason|
          case reason&.to_sym
          when :outside_enrollment
            _('patient did not have an active enrollment on the date of the activity')
          when :call_not_reached
            _('phone or video calls are not payable if the patient was not reached')
          when :outreach_past_cutoff
            _('outreach activities are not payable after the outreach period')
          when :limit_outreaches_per_month_exceeded
            _('too many outreach activities in the month')
          when :limit_months_outreach_exceeded
            _('too many months with outreach activities')
          when :limit_activities_per_month_without_careplan_exceeded
            _('too many non-outreach activities in the month')
          when :activity_outside_of_engagement_without_careplan
            _('engagement period has ended, and there is no signed careplan')
          when :limit_months_without_careplan_exceeded
            _('too many months with non-outreach activities and no signed careplan')
          end
        end
      elsif ! procedure_valid?
        reasons = []
        reasons << _('the date of the activity is missing') unless date_of_activity.present?
        reasons << _('no activity was specified') unless activity.present?
        reasons << _('no mode of contact') unless mode_of_contact.present?
        reasons << _('no indication if the client was reached') unless reached_client.present?
        reasons << _('invalid procedure code') if reasons.blank?

        reasons
      end
    end

    def procedure_with_modifiers
      # sort is here since this is used as a key to match against other data
      ([procedure_code] + modifiers.sort).join('>').to_s
    end

    def any_submitted_of_type_for_day_for_patient?
      same_of_type_for_day_for_patient.submitted.exists?
    end

    def occurred_during_any_enrollment?
      date_of_activity.present? && patient.patient_referrals.active_within_range(start_date: date_of_activity, end_date: date_of_activity).exists?
    end

    def occurred_during_enrollment?
      date_of_activity.present? && patient.patient_referrals.contributing.active_within_range(start_date: date_of_activity, end_date: date_of_activity).exists?
    end

    def occurred_within_three_months_of_enrollment?
      date_of_activity.present? && patient.first_n_contributed_days_of_enrollment(90).include?(date_of_activity)
    end

    # at the time of this call does the patient have
    # a valid care plan covering the date_of_activity
    def patient_has_valid_care_plan?
      return false if patient.care_plan_renewal_date.blank?
      return false unless date_of_activity.present?

      date_of_activity >= patient.care_plan_provider_signed_date && date_of_activity < patient.care_plan_renewal_date
    end

    # Is a valid care_plan missing for the date_of_activity?. This is much
    # slower and more complex than patient_has_valid_care_plan? which
    # can be used to determine if a patent currently has a care plan more efficiently.
    #
    # This will return:
    #   nil if there was no referral containing the activity
    #   false if the QA was during an enrollment where a valid care plan can be found
    #   true if no such care plan can be found.
    def missing_care_plan?
      # These have changed over time but this report
      # cares only about the current rules for now
      engagement_period_in_days = ::Health::PatientReferral::ENGAGEMENT_IN_DAYS
      allowed_gap_in_days = ::Health::PatientReferral::REENROLLMENT_REQUIRED_AFTER_DAYS

      # We are going to need to look at most referrals for this patient
      patient_referrals = patient.patient_referrals.sort_by(&:enrollment_start_date)

      # Are there any referrals that were active at the time of this activity?
      # Enrollments are intended to non-overlapping but are not always.
      # We respect a pending disenrollment assumed by insurer but not yet accepted by provider
      contributing_referrals = patient_referrals.select do |r|
        r.active_on?(date_of_activity)
      end.to_set

      # 0 active referrals means a valid care plan is irrelevant/impossible
      return nil if contributing_referrals.none?

      # Search backward in time and collect any referrals
      # where the gaps between the its disenrollment_date
      # and any of our existing contributions is <= allowed_gap_in_days
      # This is O(n^2) but N is expected to stay small
      patient_referrals.reverse_each do |r|
        next if r.enrollment_start_date > date_of_activity # don't need to consider this one, it started after the QA
        next if r.in?(contributing_referrals) # already found it

        close_enough = contributing_referrals.any? do |r2|
          r_disnrollment = r.actual_or_pending_disenrollment_date
          r_disnrollment.nil? || (r2.enrollment_start_date - r_disnrollment).to_i.between?(0, allowed_gap_in_days)
        end
        contributing_referrals << r if close_enough
      end

      # Just in case
      contributing_referrals = contributing_referrals.to_a.sort_by(&:enrollment_start_date)

      # We have engagement_period_in_days of *accumulated* enrollment to get a care plan signed
      # before that date we are in a grace period and the plan is not considered missing yet.
      enrolled_dates = Set.new
      contributing_referrals.each do |r|
        enrolled_dates += r.enrolled_days_to_date
        break if enrolled_dates.size >= engagement_period_in_days
      end

      # We have not yet been enrolled 150 days so there is still time for a care plan to arrive
      return false if enrolled_dates.size < engagement_period_in_days

      pcp_signed_plans = patient.careplans.select(&:provider_signed_on)
      # Fast fail: no pcp signed plans at all.
      return true if pcp_signed_plans.none?

      # If a signed care plan was prepared at *any time* within the contributing_referrals containing
      # this activity than the activity is covered by the plan except for the activities to
      # create the plan itself. i.e. it does not matter if the plan was signed before or after the care plan.
      first_enrollment_date = contributing_referrals.first.enrollment_start_date
      last_enrollment_date = contributing_referrals.last.actual_or_pending_disenrollment_date
      contributing_care_plans = pcp_signed_plans.select do |cp|
        # Not sure on this... dont penalize the patient if the provider was late signing it
        cp_date = [cp.provider_signed_on, cp.patient_signed_on].compact.min
        (
          # 8/3/2021 -- JS asked that careplan expiration dates be ignored when deciding if it was missing.
          # (cp.expires_on.nil? || date_of_activity <= cp.expires_on) &&
          (cp_date >= first_enrollment_date) &&
          (last_enrollment_date.nil? || cp_date <= last_enrollment_date)
        )
      end
      return false if contributing_care_plans.any? && !activity.in?(['care_planning', 'pctp_signed'])

      # Couldn't find one meeting any of or conditions, thus it's missing
      return true
    end

    def patient_has_signed_careplan?
      self.class.where(
        activity: 'pctp_signed',
        patient_id: patient_id,
      ).exists?
    end

    def no_signed_careplan?
      ! patient_has_signed_careplan?
    end

    def once_per_day_procedure_codes
      [
        'G0506', # cha
        'T2024', # care planning
        'T2024>U4', # completed care planning
        'T1023', # screening completed
        'T1023>U6', # referral to ACO
      ]
    end

    def in_first_three_months_procedure_codes
      self.class.in_first_three_months_procedure_codes
    end

    def self.in_first_three_months_procedure_codes
      [
        'G9011', # outreach
      ]
    end

    def self.in_first_three_months_activities
      activities.select do |_, act|
        in_first_three_months_procedure_codes.include?(act[:code].to_s)
      end.keys
    end

    # def restricted_procedure_codes
    #   once_per_day_procedure_codes + in_first_three_months_procedure_codes
    # end

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
        'T2024>U4'.to_sym => [
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
        'G9007>U5'.to_sym => [
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
        'T1023>U6'.to_sym => [
          'U1',
          'U2',
          'U3',
        ],
      }
    end
  end
end
