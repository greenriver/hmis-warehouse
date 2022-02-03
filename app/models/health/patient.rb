###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Risk: Describes a patient and contains PHI
# Control: PHI attributes documented
module Health
  class Patient < Base
    extend OrderAsSpecified

    include RailsDrivers::Extensions
    include ArelHelper
    acts_as_paranoid

    phi_patient :id
    phi_attr :id_in_source, Phi::MedicalRecordNumber
    phi_attr :first_name, Phi::Name
    phi_attr :middle_name, Phi::Name
    phi_attr :last_name, Phi::Name
    phi_attr :aliases, Phi::Name
    phi_attr :birthdate, Phi::Date
    phi_attr :allergy_list, Phi::NeedsReview
    phi_attr :primary_care_physician, Phi::SmallPopulation
    phi_attr :transgender, Phi::SmallPopulation
    # phi_attr :race, Phi::SmallPopulation
    # phi_attr :ethnicity, Phi::SmallPopulation
    phi_attr :veteran_status, Phi::SmallPopulation
    phi_attr :ssn, Phi::Ssn
    phi_attr :client_id, Phi::OtherIdentifier
    # phi_attr :gender, Phi::SmallPopulation
    phi_attr :consent_revoked, Phi::Date
    phi_attr :medicaid_id, Phi::HealthPlan
    phi_attr :housing_status, Phi::NeedsReview
    phi_attr :housing_status_timestamp, Phi::Date
    phi_attr :pilot, Phi::SmallPopulation
    phi_attr :engagement_date, Phi::Date
    phi_attr :death_date, Phi::Date
    phi_attr :care_coordinator_id, Phi::SmallPopulation
    phi_attr :coverage_level, Phi::SmallPopulation
    phi_attr :coverage_inquiry_date, Phi::Date
    phi_attr :nurse_care_manager_id, Phi::SmallPopulation

    has_many :epic_patients, primary_key: :medicaid_id, foreign_key: :medicaid_id, inverse_of: :patient
    has_many :appointments, through: :epic_patients
    has_many :medications, through: :epic_patients
    has_many :problems, through: :epic_patients
    has_many :visits, through: :epic_patients
    has_many :epic_goals, through: :epic_patients
    has_many :epic_case_notes, through: :epic_patients
    has_many :epic_case_note_qualifying_activities, through: :epic_patients
    has_many :epic_team_members, through: :epic_patients
    has_many :epic_qualifying_activities, through: :epic_patients
    has_many :epic_careplans, through: :epic_patients
    has_many :epic_chas, through: :epic_patients
    has_many :epic_ssms, through: :epic_patients
    has_many :epic_housing_statuses, through: :epic_patients

    has_many :ed_nyu_severities, class_name: 'Health::Claims::EdNyuSeverity', primary_key: :medicaid_id, foreign_key: :medicaid_id
    has_many :ed_ip_visits, primary_key: :medicaid_id, foreign_key: :medicaid_id

    # has_many :teams, through: :careplans
    # has_many :team_members, class_name: 'Health::Team::Member', through: :team
    has_many :team_members, class_name: 'Health::Team::Member'

    has_many :consolidated_contacts, class_name: 'Health::Contact'

    # has_many :goals, class_name: 'Health::Goal::Base', through: :careplans
    has_many :goals, class_name: 'Health::Goal::Base'
    # NOTE: not sure if this is the right order but it seems they should have some kind of order
    has_many :hpc_goals, -> { order 'health_goals.start_date' }, class_name: 'Health::Goal::Hpc'

    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', optional: true

    has_one :claims_roster, class_name: 'Health::Claims::Roster', primary_key: :medicaid_id, foreign_key: :medicaid_id
    has_many :amount_paids, class_name: 'Health::Claims::AmountPaid', primary_key: :medicaid_id, foreign_key: :medicaid_id
    has_many :self_sufficiency_matrix_forms
    has_one :recent_ssm_form, -> do
      merge(Health::SelfSufficiencyMatrixForm.recent)
    end, class_name: 'Health::SelfSufficiencyMatrixForm'
    has_many :hmis_ssms, -> do
      merge(GrdaWarehouse::HmisForm.self_sufficiency)
    end, class_name: 'GrdaWarehouse::HmisForm', through: :client, source: :source_hmis_forms
    has_many :sdh_case_management_notes
    has_many :participation_forms
    has_one :recent_participation_form, -> do
      merge(Health::ParticipationForm.recent)
    end, class_name: 'Health::ParticipationForm'
    has_many :release_forms
    has_one :recent_release_form, -> do
      merge(Health::ReleaseForm.recent)
    end, class_name: 'Health::ReleaseForm'
    has_many :comprehensive_health_assessments
    has_one :recent_cha_form, -> do
      merge(Health::ComprehensiveHealthAssessment.recent)
    end, class_name: 'Health::ComprehensiveHealthAssessment'
    has_many :careplans
    has_one :recent_pctp_form, -> do
      merge(Health::Careplan.recent)
    end, class_name: 'Health::Careplan'

    has_many :services
    has_many :equipments
    has_many :backup_plans

    has_one :patient_referral, -> do
      merge(PatientReferral.current)
    end
    has_many :patient_referrals
    has_one :health_agency, through: :patient_referral, source: :assigned_agency
    belongs_to :care_coordinator, class_name: 'User', optional: true
    belongs_to :nurse_care_manager, class_name: 'User', optional: true
    has_many :qualifying_activities
    has_many :status_dates

    scope :pilot, -> { where pilot: true }
    scope :hpc, -> { where pilot: false }
    scope :bh_cp, -> { where pilot: false }

    scope :participating, -> do
      joins(:patient_referral).
        merge(Health::PatientReferral.not_confirmed_rejected)
    end

    scope :active_on_date, ->(date) do
      joins(:patient_referrals).
        merge(Health::PatientReferral.where(
                hpr_t[:enrollment_start_date].lteq(date).
                  and(hpr_t[:disenrollment_date].gt(date).
                    or(hpr_t[:disenrollment_date].eq(nil))),
              ))
    end

    scope :active_between, ->(start_date, end_date) do
      where(
        id: Health::PatientReferral.active_within_range(
          start_date: start_date,
          end_date: end_date,
        ).select(:patient_id),
      )
    end

    scope :unprocessed, -> { where client_id: nil }
    scope :consent_revoked, -> { where.not(consent_revoked: nil) }
    scope :consented, -> { where(consent_revoked: nil) }

    scope :with_unsent_eligibility_notification, -> { where eligibility_notification: nil }
    scope :program_ineligible, -> do
      where coverage_level: [
        Health::Patient.coverage_level_none_value,
        Health::Patient.coverage_level_standard_value,
      ]
    end
    scope :no_coverage, -> { where coverage_level: Health::Patient.coverage_level_none_value }
    scope :standard_coverage, -> { where coverage_level: Health::Patient.coverage_level_standard_value }

    scope :full_text_search, ->(text) do
      text_search(text, patient_scope: current_scope)
    end

    scope :has_signed_participation_form, -> do
      joins(:participation_forms).merge(Health::ParticipationForm.signed)
    end

    scope :has_ssm, -> do
      # This lives in the warehouse DB and must be materialized
      hmis_ssm_client_ids = GrdaWarehouse::Hud::Client.joins(:source_hmis_forms).merge(GrdaWarehouse::HmisForm.self_sufficiency).distinct.pluck(:client_id)
      ssm_patient_id_scope = Health::SelfSufficiencyMatrixForm.completed.distinct.select(:patient_id)
      epic_ssm_patient_id_scope = Health::EpicSsm.distinct.joins(:patient).select(hp_t[:id].to_sql)

      where(
        arel_table[:client_id].in(hmis_ssm_client_ids).
        or(
          arel_table[:id].in(Arel.sql(ssm_patient_id_scope.to_sql)),
        ).
        or(
          arel_table[:id].in(Arel.sql(epic_ssm_patient_id_scope.to_sql)),
        ),
      )
    end

    scope :has_cha, -> do
      cha_patient_id_scope = Health::ComprehensiveHealthAssessment.reviewed.distinct.select(:patient_id)
      epic_cha_patient_id_scope = Health::EpicCha.distinct.joins(:patient).select(hp_t[:id].to_sql)

      where(
        arel_table[:id].in(Arel.sql(cha_patient_id_scope.to_sql)).
        or(
          arel_table[:id].in(Arel.sql(epic_cha_patient_id_scope.to_sql)),
        ),
      )
    end

    # at least one of the following is true
    # No SSM
    # No Participation Form
    # No Release Form
    # No CHA
    scope :not_engaged, -> do
      where.not(id: engaged.select(:id))
    end

    # all must be true
    # Has SSM
    # Has Participation Form
    # Has Release Form
    # Has CHA
    scope :engaged, ->(on: Date.current) do
      # This lives in the warehouse DB and must be materialized
      # hmis_ssm_client_ids = GrdaWarehouse::Hud::Client.joins(:source_hmis_forms).merge(GrdaWarehouse::HmisForm.self_sufficiency).distinct.pluck(:id)
      first_date = Health::PatientReferral.first_enrollment_start_date&.to_time || '2015-01-01'.to_time
      ssm_patient_id_scope = Health::SelfSufficiencyMatrixForm.distinct.
        completed.
        allowed_for_engagement.
        where(completed_at: (first_date..on.to_time)).
        select(:patient_id)

      epic_ssm_patient_id_scope = Health::EpicSsm.distinct.
        allowed_for_engagement.
        where(ssm_updated_at: (first_date..on.to_time)).
        select(hp_t[:id].to_sql)

      participation_form_patient_id_scope = Health::ParticipationForm.distinct.
        valid.
        allowed_for_engagement.
        select(:patient_id)

      release_form_patient_id_scope = Health::ReleaseForm.distinct.
        valid.
        allowed_for_engagement.
        select(:patient_id)

      cha_patient_id_scope = Health::ComprehensiveHealthAssessment.distinct.
        reviewed.
        allowed_for_engagement.
        where(reviewed_at: (first_date..on.to_time)).
        select(:patient_id)

      epic_cha_patient_id_scope = Health::EpicCha.distinct.
        allowed_for_engagement.
        where(cha_updated_at: (first_date..on.to_time)).
        select(hp_t[:id].to_sql)

      pctp_signed_patient_id_scope = Health::Careplan.distinct.
        pcp_signed.
        where(provider_signed_on: (first_date..on.to_time)).
        select(:patient_id)
      # epic_careplan_patient_id_scope = Health::EpicCareplan.distinct.joins(:patient).select(hp_t[:id].to_sql)

      where(
        arel_table[:id].in(Arel.sql(participation_form_patient_id_scope.to_sql)).
        and(
          arel_table[:id].in(Arel.sql(release_form_patient_id_scope.to_sql)),
        ).
        and(
          arel_table[:id].in(Arel.sql(cha_patient_id_scope.to_sql)).
          or(
            arel_table[:id].in(Arel.sql(epic_cha_patient_id_scope.to_sql)),
          ),
        ).
        and(
          arel_table[:id].in(Arel.sql(ssm_patient_id_scope.to_sql)).
          or(
            arel_table[:id].in(Arel.sql(epic_ssm_patient_id_scope.to_sql)),
          ),
        ).
        and(
          arel_table[:id].in(Arel.sql(pctp_signed_patient_id_scope.to_sql)),
        ),
      )
    end

    scope :engagement_required_by, ->(date) do
      not_engaged.where(arel_table[:engagement_date].lteq(date))
    end

    scope :engagement_ending, -> do
      engagement_required_by(1.months.from_now)
    end

    # patients with no qualifying activities in the past month
    scope :no_recent_qualifying_activities, -> do
      where.not(
        id: Health::QualifyingActivity.in_range(1.months.ago..Date.current).
          distinct.select(:patient_id),
      )
    end

    # patients with no payable qualifying activities in the current calendar month
    scope :no_qualifying_activities_this_month, -> do
      where.not(
        id: Health::QualifyingActivity.
          payable.
          not_valid_unpayable.
          in_range(Date.current.beginning_of_month..Date.current).
          distinct.select(:patient_id),
      )
    end

    scope :received_qualifying_activities_within, ->(range) do
      where(
        id: Health::QualifyingActivity.in_range(range).
          distinct.select(:patient_id),
      )
    end

    scope :with_unsubmitted_qualifying_activities_within, ->(range) do
      where(
        id: Health::QualifyingActivity.unsubmitted.in_range(range).
          distinct.select(:patient_id),
      )
    end

    scope :with_housing_status, -> do
      where.not(housing_status: [nil, '']).where.not(housing_status_timestamp: nil)
    end

    scope :enrolled_before, ->(date) do
      joins(:status_dates).merge(Health::StatusDate.enrolled_before(date))
    end

    scope :engaged_before, ->(date) do
      joins(:status_dates).merge(Health::StatusDate.engaged_before(date))
    end

    scope :engaged_for, ->(range) do
      where(id: Health::StatusDate.engaged.group(h_sd_t[:patient_id]).
        having(nf('count', [h_sd_t[:patient_id]]).between(range)).select(:patient_id))
    end

    delegate :effective_date, to: :patient_referral
    delegate :enrollment_start_date, to: :patient_referral
    delegate :aco, to: :patient_referral

    self.source_key = :PAT_ID

    def self.cfind client_id
      find_by(client_id: client_id)
    end

    def self.accessible_by_user user
      # health admins can see all, including consent revoked
      if user.can_administer_health?
        all
      # everyone else can only see consented patients
      elsif user.present? && (user.can_edit_client_health? || user.can_view_client_health?)
        consented
      else
        none
      end
    end

    def visible_to(user)
      return false unless user
      return true if user.can_administer_health?
      return true if (user.can_edit_client_health? || user.can_view_client_health?) && consent_revoked.blank?

      user.can_view_patients_for_own_agency? && user.health_agencies.include?(health_agency)
    end

    def contributing_enrollment_start_date
      patient_referrals.contributing.minimum(:enrollment_start_date)
    end

    def current_days_enrolled
      referral = patient_referral
      return 0 unless referral

      end_date = referral.actual_or_pending_disenrollment_date || Date.current
      # This only happens with demo data
      return 0 unless referral.enrollment_start_date

      (end_date - referral.enrollment_start_date).to_i
    end

    def contributed_days_enrolled
      contributed_dates.count - 1 # Don't count today
    end

    def prior_contributed_days_enrolled
      prior_contributed_dates.count
    end

    def prior_contributed_dates
      # Prior enrollments, but remove current to prevent overlap
      prior_contributed_enrollment_ranges.map(&:to_a).flatten.uniq - current_enrollment_range.to_a
    end

    def contributed_dates
      contributed_enrollment_ranges.map(&:to_a).flatten.uniq
    end

    def first_n_contributed_days_of_enrollment(day_count)
      contributed_dates.first(day_count)
    end

    def current_disenrollment_date
      patient_referral.actual_or_pending_disenrollment_date
    end

    def current_enrollment_range
      end_date = current_disenrollment_date || Date.current
      (patient_referral.enrollment_start_date..end_date)
    end

    # def prior_contributed_enrollment_ranges
    #   patient_referrals.contributing.prior.map do |referral|
    #     (referral.enrollment_start_date..referral.actual_or_pending_disenrollment_date)
    #   end
    # end

    def prior_contributed_enrollment_ranges
      patient_referrals.map do |referral|
        next unless referral.contributing?
        next if referral.current?
        next unless referral.enrollment_start_date

        (referral.enrollment_start_date..referral.actual_or_pending_disenrollment_date)
      end
    end

    # def contributed_enrollment_ranges
    #   patient_referrals.contributing.map do |referral|
    #     end_date = referral.actual_or_pending_disenrollment_date || Date.current
    #     (referral.enrollment_start_date..end_date)
    #   end
    # end

    def contributed_enrollment_ranges
      patient_referrals.map do |referral|
        next unless referral.contributing?
        next unless referral.enrollment_start_date

        end_date = referral.actual_or_pending_disenrollment_date || Date.current
        (referral.enrollment_start_date..end_date)
      end.compact
    end

    def careplan_signed_in_122_days?
      care_plan_signed? && (care_plan_provider_signed_date - patient_referral.enrollment_start_date).to_i <= 122
    end

    def reenroll!(referral)
      # Create a "Care Plan Complete QA" if the patient has an unexpired care plan as of the enrollment start date
      return unless careplans.fully_signed.where(h_cp_t[:provider_signed_on].gteq(referral.enrollment_start_date - 1.year)).exists?

      user = User.setup_system_user
      qualifying_activities.create(
        activity: :pctp_signed,
        date_of_activity: referral.enrollment_start_date,

        user_id: user.id,
        user_full_name: user.name,
        source: referral,
        follow_up: 'None',
        mode_of_contact: :other,
        mode_of_contact_other: 'MassHealth re-enrollment',
        reached_client: :yes,
      )
    end

    def age(on_date:)
      GrdaWarehouse::Hud::Client.age(date: on_date, dob: birthdate)
    end

    # Priority:
    # Authoritative: Epic (epic_patient)
    # Updates from MassHealth (patient_referral)
    def update_demographics_from_sources
      if patient_referral
        self.first_name = patient_referral.first_name
        self.middle_name = patient_referral.middle_initial
        self.last_name = patient_referral.last_name
        self.birthdate = patient_referral.birthdate
        self.gender = patient_referral.gender
      end
      if epic_patient
        self.first_name = epic_patient.first_name
        self.middle_name = epic_patient.middle_name
        self.last_name = epic_patient.last_name
        self.aliases = epic_patient.aliases
        self.birthdate = epic_patient.birthdate
        self.allergy_list = epic_patient.allergy_list
        self.primary_care_physician = epic_patient.primary_care_physician
        self.transgender = epic_patient.transgender
        self.race = epic_patient.race
        self.ethnicity = epic_patient.ethnicity
        self.veteran_status = epic_patient.veteran_status
        self.ssn = epic_patient.ssn
        self.gender = epic_patient.gender
        self.housing_status = epic_patient.housing_status
        self.housing_status_timestamp = epic_patient.housing_status_timestamp
        self.death_date = epic_patient.death_date
        self.pilot = epic_patient.pilot
      end

      if client.present? && client.data_source_id == GrdaWarehouse::DataSource.health_authoritative_id
        client.FirstName = first_name
        client.LastName = last_name
        client.SSN = ssn
        client.save if client.changed?
      end

      save if changed?
    end

    def self.update_demographic_from_sources
      all.each(&:update_demographics_from_sources)
    end

    def available_team_members
      team_members.map { |t| [t.full_name, t.id] }
    end

    def days_to_engage
      return 0 unless engagement_date.present?

      (engagement_date - Date.current).to_i.clamp(0, 365)
    end

    def self.outreach_cutoff_span
      90.days
    end

    def outreach_cutoff_date
      if enrollment_start_date.present?
        (enrollment_start_date + self.class.outreach_cutoff_span - prior_contributed_days_enrolled).to_date
      else
        (Date.current + self.class.outreach_cutoff_span).to_date
      end
    end

    def chas
      @chas ||= (
          comprehensive_health_assessments.order(completed_at: :desc).to_a +
          epic_chas.order(cha_updated_at: :desc)
        ).sort_by do |f|
        if f.is_a? Health::ComprehensiveHealthAssessment
          f.completed_at || DateTime.current
        elsif f.is_a? GrdaWarehouse::HmisForm
          f.collected_at || DateTime.current
        elsif f.is_a? Health::EpicCha
          f.cha_updated_at || DateTime.current
        end
      end
    end

    def health_files
      Health::HealthFile.where(client_id: client.id)
    end

    def accessible_by_user user
      return false unless user.present?
      return true if user.can_administer_health?

      if pilot_patient?
        return true if consented? && (user.can_edit_client_health? || user.can_view_client_health?)
      elsif patient_referrals.exists? && user.has_some_patient_access? # hpc_patient?
        return true
      end
      false
    end

    def anything_expiring?
      release_status.present? || cha_status.present? || ssm_status.present? || careplan_status.present?
    end

    def participation_form_status
      @participation_form_status ||= if active_participation_form? && ! expiring_participation_form?
        # Valid
      elsif expiring_participation_form?
        "Participation form expires #{participation_forms.recent.expiring_soon.during_current_enrollment.last.expires_on}"
      elsif expired_participation_form?
        "Participation expired on #{participation_forms.recent.expired.during_current_enrollment.last.expires_on}"
      end
    end

    private def active_participation_form?
      @active_participation_form ||= participation_forms.active.during_current_enrollment.exists?
    end

    private def expiring_participation_form?
      @expiring_participation_form ||= participation_forms.expiring_soon.during_current_enrollment.exists?
    end

    private def expired_participation_form?
      @expired_participation_form ||= participation_forms.expired.during_current_enrollment.exists?
    end

    def release_status
      @release_status ||= if active_release? && ! expiring_release?
        # Valid
      elsif expiring_release?
        "Release of information expires #{release_forms.recent.expiring_soon.during_current_enrollment.last.expires_on}"
      elsif expired_release?
        "Release of information expired on #{release_forms.recent.expired.during_current_enrollment.last.expires_on}"
      end
    end

    private def active_release?
      @active_release ||= release_forms.active.during_current_enrollment.exists?
    end

    private def expiring_release?
      @expiring_release ||= release_forms.expiring_soon.during_current_enrollment.exists?
    end

    private def expired_release?
      @expired_release ||= release_forms.expired.during_current_enrollment.exists?
    end

    def cha_status
      @cha_status ||= if active_cha? && ! expiring_cha?
        # Valid
      elsif expiring_cha?
        "Comprehensive Health Assessment expires #{comprehensive_health_assessments.recent.expiring_soon.during_current_enrollment.last.expires_on}"
      elsif expired_cha?
        "Comprehensive Health Assessment expired on #{comprehensive_health_assessments.recent.expired.during_current_enrollment.last.expires_on}"
      end
    end

    private def active_cha?
      @active_cha ||= comprehensive_health_assessments.active.during_current_enrollment.exists?
    end

    private def expiring_cha?
      @expiring_cha ||= comprehensive_health_assessments.recent.expiring_soon.during_current_enrollment.exists?
    end

    private def expired_cha?
      @expired_cha ||= comprehensive_health_assessments.recent.expired.during_current_enrollment.exists?
    end

    def ssm_status
      @ssm_status ||= if active_ssm? && ! expiring_ssm?
        # Valid
      elsif expiring_ssm?
        "Self-Sufficiency Matrix Form expires #{self_sufficiency_matrix_forms.completed.during_current_enrollment.last.expires_on}"
      elsif expired_ssm?
        "Self-Sufficiency Matrix Form expired on #{self_sufficiency_matrix_forms.completed.during_current_enrollment.last.expires_on}"
      end
    end

    private def active_ssm?
      @active_ssm ||= self_sufficiency_matrix_forms.completed.active.during_current_enrollment.exists?
    end

    private def expiring_ssm?
      @expiring_ssm ||= self_sufficiency_matrix_forms.completed.expiring_soon.during_current_enrollment.exists?
    end

    private def expired_ssm?
      @expired_ssm ||= self_sufficiency_matrix_forms.completed.expired.during_current_enrollment.exists?
    end

    def careplan_status
      @careplan_status ||= if active_careplan? && ! expiring_careplan?
        # Valid
      elsif missing_careplan?
        'Care plan not completed by required date'
      elsif expiring_careplan?
        "Care plan expires #{careplans.fully_signed.recent.during_current_enrollment.last.expires_on}"
      elsif expired_careplan?
        "Care plan expired on #{careplans.fully_signed.recent.during_current_enrollment.last.expires_on}"
      end
    end

    private def active_careplan?
      @active_careplan ||= careplans.active.during_current_enrollment.exists?
    end

    private def missing_careplan?
      @missing_careplan ||= current_days_enrolled > 150 && ! careplans.during_current_enrollment.fully_signed.exists?
    end

    private def expiring_careplan?
      @expiring_careplan ||= careplans.fully_signed.recent.expiring_soon.during_current_enrollment.exists?
    end

    private def expired_careplan?
      @expired_careplan ||= careplans.fully_signed.recent.expired.during_current_enrollment.exists?
    end

    def pilot_patient?
      pilot == true
    end

    def hpc_patient? # also referred to as BH CP
      ! pilot_patient?
    end

    def recent_cha
      @recent_cha ||= comprehensive_health_assessments.recent&.first
    end

    def recent_case_management_note
      @recent_case_management_note ||= sdh_case_management_notes.recent.with_phone&.first
    end

    # Provide a means of seeing all the case notes, regardless of data source in one location
    def case_notes_for_display
      case_notes = []
      case_notes += client.health_touch_points.case_management_notes.order(collected_at: :desc).map do |form|
        {
          type: :touch_point,
          id: form.id,
          title: form.assessment_type,
          sub_title: 'From ETO',
          date: form.collected_at&.to_date,
          user: form.staff,
        }
      end
      case_notes += sdh_case_management_notes.order(date_of_contact: :desc).map do |form|
        {
          type: :warehouse,
          id: form.id,
          title: form.topics.join(', ').html_safe,
          sub_title: form.title || 'No Title',
          date: form.date_of_contact&.to_date || form.completed_on&.to_date,
          user: form.user&.name,
        }
      end
      case_notes += epic_case_notes.order(contact_date: :desc).map do |form|
        date = form.contact_date
        # Epic doesn't send timezone, but sends the dates all as mid-night,
        # so assume it's in the local timezone
        date = Time.zone.local_to_utc(date).to_date if date
        {
          type: :epic,
          id: form.id,
          title: form.encounter_type,
          sub_title: 'From Epic',
          date: date,
          user: form.provider_name,
        }
      end
      case_notes.sort_by { |m| m[:date] }.reverse
    end

    def most_recent_ssn
      [
        [ssn.presence, updated_at.to_i],
        [recent_cha&.ssn.presence, recent_cha&.updated_at.to_i],
        [client.SSN.presence, client.DateUpdated.to_i],
      ].sort_by(&:last).map(&:first).compact.reverse.first
    end

    def preferred_communication
      recent_cha&.answer(:r_q1)
    end

    def most_recent_phone
      note = recent_case_management_note
      [
        [recent_cha&.phone.presence, recent_cha&.updated_at.to_i],
        [note&.client_phone_number.presence, note&.updated_at.to_i],
      ].sort_by(&:last).map(&:first).compact.reverse.first
    end

    def most_recent_contact
      consolidated_contacts.order(collected_on: :desc).first
    end

    def phone_message_ok
      if preferred_communication == 'Phone' &&
        recent_cha&.answer(:r_q2) == 'Yes'
        ', message ok'
      end
    end

    def advanced_directive?
      advanced_directive_answer == 'Yes'
    end

    def advanced_directive_answer
      recent_cha&.answer(:r_q4)
    end

    def advanced_directive_type
      recent_cha&.answer(:r_q5)
    end

    def develop_advanced_directive?
      recent_cha&.answer(:r_q7) != 'No'
    end

    def veteran_status
      Rails.cache.fetch(['veteran_status', id], expires_in: 2.hours) do
        status = recent_cha&.answer(:r_q3)
        if status == 'Yes'
          'Veteran'
        elsif status == 'No'
          'Non-veteran'
        end

        nil
      end
    end

    def self.coverage_level_none_value
      'none'
    end

    def coverage_level_none?
      coverage_level == Health::Patient.coverage_level_none_value
    end

    def self.coverage_level_standard_value
      'standard'
    end

    def coverage_level_standard?
      coverage_level == Health::Patient.coverage_level_standard_value
    end

    def self.coverage_level_managed_value
      'managed'
    end

    def coverage_level_managed?
      coverage_level == Health::Patient.coverage_level_managed_value
    end

    # most recently updated Epic Patient
    def epic_patient
      return false unless epic_patients.exists?

      epic_patients.order(updated_at: :desc).first
    end

    def email
      recent_cha&.answer(:r_q1b).presence
    end

    def current_email
      @current_email ||= email || client.email || 'patient@openpath.biz'
    end

    def advanced_directive
      {
        name: recent_cha&.answer(:r_q6a),
        relationship: recent_cha&.answer(:r_q6b),
        address: recent_cha&.answer(:r_q6c),
        phone: recent_cha&.answer(:r_q6d),
        comments: recent_cha&.answer(:r_q6e),
      }
    end

    def engaged?
      self.class.engaged.where(id: id).exists?
      # ssms? && participation_forms.reviewed.exists? && release_forms.reviewed.exists? && comprehensive_health_assessments.reviewed.exists?
    end

    def ssms?
      self_sufficiency_matrix_forms.completed.exists? || hmis_ssms.exists?
    end

    def ssms
      @ssms ||= (
          hmis_ssms.order(collected_at: :desc).to_a +
          self_sufficiency_matrix_forms.order(completed_at: :desc).to_a +
          epic_ssms.order(ssm_updated_at: :desc)
        ).sort_by do |f|
        if f.is_a? Health::SelfSufficiencyMatrixForm
          f.completed_at || DateTime.current
        elsif f.is_a? GrdaWarehouse::HmisForm
          f.collected_at || DateTime.current
        elsif f.is_a? Health::EpicSsm
          f.ssm_updated_at || DateTime.current
        end
      end
    end

    def qualified_activities_since date: 1.months.ago
      qualifying_activities.in_range(date..Date.tomorrow)
    end

    def valid_qualified_activities_since date: 1.months.ago
      qualified_activities_since(date: date).payable
    end

    def valid_payable_qualified_activities_since date: 1.months.ago
      qualified_activities_since(date: date).payable.not_valid_unpayable
    end

    def valid_unpayable_qualified_activities_since date: 1.months.ago
      qualified_activities_since(date: date).payable.valid_unpayable
    end

    def import_epic_team_members
      # I think this updates this for changes made here PT story #158636393
      potential_team = epic_team_members.unprocessed.to_a
      return unless potential_team.any?

      potential_team.each do |epic_member|
        if epic_member.name.include?(',')
          (last_name, first_name) = epic_member.name.split(',', 2).map(&:strip)
        else
          (first_name, last_name) = epic_member.name.split(' ', 2)
        end
        user = User.find_by(email: 'noreply@greenriver.com')
        # Use the PCP type if we have it
        relationship = epic_member.pcp_type || epic_member.relationship
        klass = Health::Team::Member.class_from_member_type_name(relationship)
        at = klass.arel_table
        if epic_member.email?
          member = klass.where(at[:email].lower.eq(epic_member.email.downcase).to_sql).
            where(patient_id: id).
            first_or_initialize
        elsif first_name && last_name
          member = klass.where(
            at[:first_name].lower.eq(first_name&.downcase).
            and(at[:last_name].lower.eq(last_name&.downcase)).to_sql,
          ).
            where(patient_id: id).
            first_or_initialize
        else
          next
        end
        member.assign_attributes(
          patient_id: id,
          user_id: user.id,
          first_name: first_name,
          last_name: last_name,
          title: epic_member.relationship,
          email: epic_member.email,
          phone: epic_member.phone,
          organization: epic_member.email&.split('@')&.last || 'Unknown',
        )
        member.save(validate: false)
        epic_member.update(processed: Time.now)
      end
    end

    def most_recent_direct_qualifying_activity_in_range range
      qualifying_activities.in_range(range).direct_contact.order(date_of_activity: :desc).limit(1).first
    end

    # these need to be direct as well (not collateral) since it must be with a member
    # to count
    def face_to_face_contact_in_range? range
      qualifying_activities.in_range(range).direct_contact.face_to_face.exists?
    end

    def consented? # Pilot
      consent_revoked.blank?
    end

    def consent_revoked? # Pilot
      consent_revoked.present?
    end

    def self.revoke_consent # Pilot
      update_all(consent_revoked: Time.now)
    end

    def self.restore_consent # Pilot
      update_all(consent_revoked: nil)
    end

    def self.clean_value key, value
      case key
      when :pilot
        value.include?('SDH')
      else
        value.presence
      end
    end

    def name
      full_name = "#{first_name} #{middle_name} #{last_name}"
      full_name << " (#{aliases})" if aliases.present?
      return full_name
    end

    def build_team_member!(team_member_class, team_member_user_id, current_user)
      user = User.find(team_member_user_id)
      team_member = team_member_class.
        where(Arel.sql(team_member_class.arel_table[:email].lower.eq(user.email.downcase).to_sql)).
        where(patient_id: id).
        first_or_initialize
      team_member.assign_attributes(
        patient_id: id,
        first_name: user.first_name,
        last_name: user.last_name,
        email: user.email,
        organization: health_agency&.name,
        user_id: current_user.id,
      )
      team_member.save!
    end

    def available_care_coordinators
      return [] unless health_agency.present?

      user_ids = Health::AgencyUser.where(agency_id: health_agency.id).pluck(:user_id)
      User.where(id: user_ids)
    end

    def available_nurse_care_managers
      return [] unless health_agency.present?

      user_ids = Health::AgencyUser.where(agency_id: health_agency.id).pluck(:user_id)
      User.where(id: user_ids)
    end

    def housing_stati
      client.case_management_notes.map do |form|
        first_section = form.answers[:sections].first
        next unless first_section.present?

        answer = form.answers[:sections].first[:questions].select do |question|
          question[:question] == 'A-6. Where did you sleep last night?'
        end.first
        status = client.class.health_housing_bucket(answer[:answer])
        OpenStruct.new(
          date: form.collected_at.to_date,
          postitive_outcome: client.class.health_housing_positive_outcome?(answer[:answer]),
          outcome: status,
          detail: answer[:answer],
        )
      end.select { |row| row.outcome.present? }.
        index_by(&:date).values.
        sort_by(&:date).reverse
    end

    def current_housing_status
      # return nil unless housing_stati.any?
      # most_recent = housing_stati.first
      # last_status = housing_stati&.second
      # if last_status.present? # FIXME
      #   most_recent.positive_change
      # end
    end

    def last_outreach_enrollment_date(user)
      client.
        service_history_enrollments.
        visible_in_window_to(user).
        entry.
        ongoing.
        so.
        maximum(:first_date_in_program)
    end

    def last_sleeping_location(user)
      service = client.service_history_services.
        service_within_date_range(start_date: 90.days.ago.to_date, end_date: Date.current).
        joins(:service_history_enrollment).
        merge(GrdaWarehouse::ServiceHistoryEnrollment.visible_in_window_to(user).entry.ongoing.residential).
        order(date: :desc).first
      return unless service.present?

      {
        date: service.date,
        location: service.service_history_enrollment&.organization&.name || 'Unable to determine location',
      }
    end

    def consented_date
      @consented_date ||= participation_forms.signed&.last&.signature_on
    end

    def ssm_completed_date
      @ssm_completed_date ||= self_sufficiency_matrix_forms.completed.maximum(:completed_at)&.to_date
    end

    def cha_completed_date
      @cha_completed_date ||= comprehensive_health_assessments.complete&.maximum(:completed_at)&.to_date
    end

    def cha_reviewed_date
      @cha_reviewed_date ||= comprehensive_health_assessments.complete&.maximum(:reviewed_at)&.to_date
    end

    def cha_renewal_date
      @cha_renewal_date ||= (cha_reviewed_date + 1.years if cha_reviewed_date.present?)
    end

    def care_plan_patient_signed_date
      @care_plan_patient_signed_date ||= careplans.maximum(:patient_signed_on)&.to_date
    end

    def care_plan_provider_signed_date
      @care_plan_provider_signed_date ||= careplans.maximum(:provider_signed_on)&.to_date
    end

    def care_plan_renewal_date
      care_plan_provider_signed_date + 1.years if care_plan_provider_signed_date.present?
    end

    def care_plan_signed?
      care_plan_patient_signed_date.present? && care_plan_provider_signed_date.present?
    end

    def most_recent_face_to_face_qa_date
      qualifying_activities.direct_contact.face_to_face.maximum(:date_of_activity)
    end

    def most_recent_qa_from_case_note
      Health::QualifyingActivity.
        where(
          source_type: [
            'GrdaWarehouse::HmisForm',
            'Health::SdhCaseManagementNote',
            'Health::EpicQualifyingActivity',
          ],
        ).
        joins(:patient).
        merge(Health::Patient.where(id: id)).
        maximum(:date_of_activity)
    end

    def ed_ip_visits_for_chart
      @ed_ip_visits_for_chart ||= begin
        visits = ed_ip_visits.valid.group(
          Arel.sql("DATE_TRUNC('month', admit_date)"),
          :encounter_major_class,
        ).count.sort_by { |(date, type), _| [date, type] }
        dates = {}
        visits.each do |(date, type), count|
          date = date.to_date
          year = date.year
          dates[year] ||= begin
            start_date = date.beginning_of_year
            (0..11).to_a.map do |offset|
              [
                start_date + offset.months,
                {
                  'Emergency' => 0,
                  'Inpatient' => 0,
                },
              ]
            end.to_h
          end
          dates[year][date]['Emergency'] += count if type == 'Emergency'
          dates[year][date]['Inpatient'] += count if type == 'Inpatient'
        end
        dates.map do |year, visits_in_year|
          [
            year,
            {
              'x' => visits_in_year.keys,
              'Emergency' => visits_in_year.values.map { |m| m['Emergency'] },
              'Inpatient' => visits_in_year.values.map { |m| m['Inpatient'] },
            },
          ]
        end.to_h
      end
    end

    def self.sort_options
      [
        { title: 'Patient Last name A-Z', column: :patient_last_name, direction: 'asc' },
        { title: 'Patient Last name Z-A', column: :patient_last_name, direction: 'desc' },
        { title: 'Patient First name A-Z', column: :patient_first_name, direction: 'asc' },
        { title: 'Patient First name Z-A', column: :patient_first_name, direction: 'desc' },
      ]
    end

    def self.column_from_sort(column: nil, direction: nil)
      {
        [:patient_last_name, :asc] => arel_table[:last_name].asc,
        [:patient_last_name, :desc] => arel_table[:last_name].desc,
        [:patient_first_name, :asc] => arel_table[:first_name].asc,
        [:patient_first_name, :desc] => arel_table[:first_name].desc,
      }[[column.to_sym, direction.to_sym]] || default
    end

    def self.default_sort_column
      :patient_last_name
    end

    def self.default_sort_direction
      :asc
    end

    def self.ransackable_scopes(_auth_object = nil)
      [:full_text_search]
    end

    def self.text_search(text, patient_scope:)
      return none unless text.present?

      text.strip!
      patient_t = arel_table

      # Explicitly search for only last, first if there's a comma in the search
      if text.include?(',')
        last, first = text.split(',').map(&:strip)
        where = patient_t[:first_name].lower.matches("#{first.downcase}%").
          and(patient_t[:last_name].lower.matches("#{last.downcase}%"))
      # Explicity search for "first last"
      elsif text.include?(' ')
        first, last = text.split(' ').map(&:strip)
        where = patient_t[:first_name].lower.matches("#{first.downcase}%").
          and(patient_t[:last_name].lower.matches("#{last.downcase}%"))
      else
        query = "%#{text.downcase}%"

        where = patient_t[:last_name].lower.matches(query).
          or(patient_t[:first_name].lower.matches(query)).
          or(patient_t[:id_in_source].lower.matches(query))
      end
      patient_scope.where(where)
    end
  end
end
