###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: Relates to a patient and contains PHI
# Control: PHI attributes documented
module Health
  class QualifyingActivity < HealthBase
    include ArelHelper
    acts_as_paranoid

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
    VERSIONS = [
      Health::QualifyingActivityV1,
      Health::QualifyingActivityV2,
    ].freeze

    [
      :mode_of_contact,
      :mode_of_contact_other,
      :reached_client,
      :reached_client_collateral_contact,
      :activity,
    ].each do |attr_sym|
      VERSIONS.each do |version|
        alias_name = (attr_sym.to_s + version::ATTRIBUTE_SUFFIX).to_sym
        alias_attribute alias_name, attr_sym
      end
    end

    def qa_version
      # If the QA doesn't have a date, use the creation date as a fallback to determine the version
      date = date_of_activity || created_at.to_date

      VERSIONS.each do |version|
        return version.new(self) if version::EFFECTIVE_DATE_RANGE.cover?(date)
      end
    end

    scope :submitted, -> do
      where.not(claim_submitted_on: nil)
    end

    scope :unsubmitted, -> do
      where(claim_submitted_on: nil)
    end

    scope :submittable, -> do
      @submittable_query ||= begin
        query = hqa_t[:activity].not_eq(nil).and(hqa_t[:follow_up].not_eq(nil))
        VERSIONS.each do |version|
          query_part = hqa_t[:date_of_activity].between(version::EFFECTIVE_DATE_RANGE).
            and(hqa_t[:activity].not_in(version::CONTACTLESS_ACTIVITIES).or(hqa_t[:mode_of_contact].not_eq(nil).and(hqa_t[:reached_client].not_eq(nil))))
          query = query.or(query_part)
        end
        query
      end

      where(@submittable_query)
    end

    scope :in_range, ->(range) do
      where(date_of_activity: range)
    end

    scope :direct_contact, -> do
      where(reached_client: :yes)
    end

    scope :face_to_face, -> do
      @face_to_face_query ||= begin
        query = nil
        VERSIONS.each do |version|
          query_part = hqa_t[:date_of_activity].between(version::EFFECTIVE_DATE_RANGE).and(hqa_t[:mode_of_contact].in(version::FACE_TO_FACE_KEYS))
          query = if query.nil?
            query_part
          else
            query.or(query_part)
          end
        end
        query
      end
      where(@face_to_face_query)
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

    def modes_of_contact
      qa_version.modes_of_contact
    end

    def client_reached
      qa_version.client_reached
    end

    def activities
      qa_version.activities
    end

    def contact_required?
      return false unless activity

      !activity.to_sym.in?(qa_version.class::CONTACTLESS_ACTIVITIES)
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

    def face_to_face?
      mode_of_contact.to_sym.in?(face_to_face_modes)
    end

    # Return the string and the key so we can check either
    def face_to_face_modes
      face_to_face_keys = qa_version.class::FACE_TO_FACE_KEYS

      modes_of_contact.select { |k, _| face_to_face_keys.include? k }.
        map { |_, m| m[:title] } + face_to_face_keys
    end

    # These validations must come after the above methods
    validates :mode_of_contact, inclusion: { in: ->(qa) { qa.modes_of_contact.keys.map(&:to_s) } }, allow_blank: true
    validates :reached_client, inclusion: { in: ->(qa) { qa.client_reached.keys.map(&:to_s) } }, allow_blank: true
    validates :activity, inclusion: { in: ->(qa) { qa.activities.keys.map(&:to_s) } }, allow_blank: true
    validates_presence_of(
      :user,
      :user_full_name,
      :source,
      :date_of_activity,
      :patient_id,
      :activity,
      :follow_up,
    )
    validates_presence_of :mode_of_contact, if: :contact_required?
    validates_presence_of :reached_client, if: :contact_required?
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

    def activity_title key
      return '' unless key

      activities[key&.to_sym].try(:[], :title) || key
    end

    def mode_of_contact_title key
      return '' unless key

      modes_of_contact[key&.to_sym].try(:[], :title) || key
    end

    def client_reached_title key
      return '' unless key

      client_reached[key&.to_sym].try(:[], :title) || key
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
      modes_of_contact[mode_of_contact&.to_sym].try(:[], :title) if mode_of_contact.present?
    end

    def title_for_client_reached
      client_reached[reached_client&.to_sym].try(:[], :title) if reached_client.present?
    end

    def title_for_activity
      activities[activity&.to_sym].try(:[], :title) if activity.present?
    end

    def procedure_code
      # ignore any modifiers
      activities[activity&.to_sym].try(:[], :code)&.split(/[ |>]/).try(:[], 0)
    end

    def outreach?
      activity == 'outreach'
    end

    def modifiers
      qa_version.modifiers
    end

    def compute_procedure_valid?
      activity_sym = activity.to_sym
      # Incomplete QAs
      return false unless date_of_activity.present? && activity.present?
      return false if (mode_of_contact.blank? || reached_client.blank?) && !activity_sym.in?(qa_version.class::CONTACTLESS_ACTIVITIES)

      # Conflicting modifiers
      return false if modifiers.include?('U2') && modifiers.include?('U3') # Marked as both f2f and indirect
      return false if modifiers.include?('U1') && modifiers.include?('HQ') # Marked as both individual and group (CP1)
      return false if modifiers.include?('U2') && modifiers.include?('95') # Marked as both f2f and telehealth
      return false if modifiers.include?('U3') && modifiers.include?('95') # Marked as both indirect and telehealth

      # In-person contacts must reach the client, EXCEPT for outreach
      return false if modifiers.include?('U2') && (!modifiers.include?('U1') || activity_sym == activities[:outreach][:code])

      valid_options = qa_version.activities[activity_sym]
      # Must not contain forbidden modifiers
      return false unless modifiers.all? { |modifier| (valid_options[:allowed] + valid_options[:required]).include?(modifier) }

      # Must contain required modifiers
      return false unless valid_options[:required].all? { |modifier| modifiers.include?(modifier) }

      true
    end

    def same_of_type_for_day_for_patient
      self.class.where(
        activity: activity,
        patient_id: patient_id,
        date_of_activity: date_of_activity,
      )
    end

    def within_per_day_limits?
      # Assumes ids are strictly increasing, so all prior QAs will have a lower id
      prior_instances = same_of_type_for_day_for_patient.where(hqa_t[:id].lt(id)).order(:id).count
      limit = qa_version.activities[activity.to_sym][:per_day]
      return true unless limit.present?

      prior_instances < limit
    end

    # CP 1.0 QAs by date limits

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
      if naturally_payable && !within_per_day_limits? # once_per_day_procedure_codes.include?(procedure_code.to_s)
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
      self.valid_unpayable_reasons = compute_valid_unpayable
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

    def compute_valid_unpayable
      @compute_valid_unpayable ||= qa_version.internal_compute_valid_unpayable
    end

    def validity_class
      return 'qa-ignored' if ignored?
      return 'qa-valid-unpayable' if valid_unpayable?
      return 'qa-valid' if procedure_valid?

      'qa-invalid'
    end

    def describe_validity_reasons
      if valid_unpayable?
        return valid_unpayable_reasons&.map do |reason|
          case reason&.to_sym
          when :outside_enrollment
            _('patient did not have an active enrollment on the date of the activity')
          when :call_not_reached
            _('phone or video calls are not payable if the patient was not reached')
          when :limit_per_day
            _('number of activities of this type per day exceeded')
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
        end || []
      elsif ! procedure_valid?
        reasons = []
        reasons << _('the date of the activity is missing') unless date_of_activity.present?
        reasons << _('no activity was specified') unless activity.present?
        if contact_required?
          reasons << _('no mode of contact') unless mode_of_contact.present?
          reasons << _('no indication if the client was reached') unless reached_client.present?
        end
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
    # def patient_has_valid_care_plan?
    #   return false if patient.care_plan_renewal_date.blank?
    #   return false unless date_of_activity.present?
    #
    #   date_of_activity >= patient.care_plan_provider_signed_date && date_of_activity < patient.care_plan_renewal_date
    # end

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
  end
end
