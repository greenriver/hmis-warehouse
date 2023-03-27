###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Stateless, QA data lives in associated model
module Health
  class QualifyingActivityV1 < QualifyingActivityBase
    FACE_TO_FACE_KEYS = [
      :in_person,
    ].freeze

    CONTACTLESS_ACTIVITIES = [].freeze

    EFFECTIVE_DATE_RANGE = (.. '2023-03-31'.to_date).freeze
    ATTRIBUTE_SUFFIX = '_v1'.freeze

    def initialize(qa)
      @qa = qa
    end

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
        verbal: {
          title: 'Verbal',
          code: 'U3',
          weight: 40,
        },
        other: {
          title: 'Other',
          code: '',
          weight: 50,
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
          allowed: ['U1', 'U2', 'U3', 'UK'],
          required: [],
        },
        cha: {
          title: 'Comprehensive Health Assessment',
          code: 'G0506',
          weight: 10,
          hidden: true,
          allowed: ['U1', 'U2', 'UK'],
          required: [],
          per_day: 1,
        },
        care_planning: {
          title: 'Care planning',
          code: 'T2024',
          weight: 20,
          hidden: true,
          allowed: ['U1', 'U2', 'U3', 'UK'],
          required: [],
          per_day: 1,
        },
        med_rec: {
          title: 'Supported Medication Reconciliation (NCM only)',
          code: 'G8427',
          weight: 21,
          allowed: ['U1', 'U2', 'U3', 'UK'],
          required: [],
        },
        care_coordination: {
          title: 'Care coordination',
          code: 'G9005',
          weight: 30,
          allowed: ['U1', 'U2', 'U3', 'UK'],
          required: [],
        },
        care_transitions: {
          title: 'Care transitions (working with care team)',
          code: 'G9007',
          weight: 40,
          allowed: ['U1', 'U2', 'U3', 'UK'],
          required: [],
        },
        discharge_follow_up: {
          title: 'Follow-up from inpatient hospital discharge (with client)',
          code: 'G9007>U5',
          weight: 50,
          allowed: ['U1', 'U2'],
          required: ['U5'],
        },
        health_coaching: {
          title: 'Health and wellness coaching',
          code: 'G9006',
          weight: 60,
          allowed: ['U1', 'U2', 'HQ'],
          required: [],
        },
        community_connection: {
          title: 'Connection to community and social services',
          code: 'G9004',
          weight: 70,
          allowed: ['U1', 'U2', 'U3', 'UK'],
          required: [],
        },
        screening_completed: {
          title: 'Social services screening completed',
          code: 'T1023',
          weight: 80,
          allowed: ['U1', 'U2', 'U3'],
          required: [],
          per_day: 1,
        },
        referral_to_aco: {
          title: 'Referral to ACO for Flexible Services',
          code: 'T1023>U6',
          weight: 90,
          allowed: ['U1', 'U2', 'U3'],
          required: ['U6'],
          per_day: 1,
        },
        pctp_signed: {
          title: 'Person-Centered Treatment Plan signed',
          code: 'T2024>U4',
          weight: 100,
          hidden: true,
          allowed: ['U1', 'U2', 'UK'],
          required: ['U4'],
          per_day: 1,
        },
        intake_completed: {
          title: 'Intake/Reassessment (completing consent/ROI, CHA, SSM, care plan)',
          code: 'G9005',
          weight: 110,
          allowed: ['U1', 'U2', 'U3', 'UK'],
          required: [],
        },
      }.sort_by { |_, m| m[:weight] }.to_h
    end

    def modifiers
      modifiers = []

      # COVID rules permitted remote contacts to be treated as in-person,
      # these rules ended with the end of the first CP program
      contact_modifier = case @qa.activity&.to_sym
      when :cha, :discharge_follow_up
        if [:phone_call, :video_call].include?(@qa.mode_of_contact&.to_sym)
          modes_of_contact[:in_person][:code]
        else
          modes_of_contact[@qa.mode_of_contact&.to_sym].try(:[], :code)
        end
      else
        modes_of_contact[@qa.mode_of_contact&.to_sym].try(:[], :code)
      end

      # attach modifiers from activity
      modifiers << activities[@qa.activity&.to_sym].try(:[], :code)&.split(/[ |>]/).try(:[], 1)

      modifiers << contact_modifier
      modifiers << client_reached[@qa.reached_client&.to_sym].try(:[], :code)

      return modifiers.reject(&:blank?).compact
    end

    def internal_compute_valid_unpayable
      reasons = []
      computed_procedure_valid = @qa.compute_procedure_valid?

      # Only valid procedures can be valid unpayable
      return nil unless computed_procedure_valid

      # Unpayable if it is a valid procedure, but it didn't occur during an enrollment
      reasons << :outside_enrollment if computed_procedure_valid && ! @qa.occurred_during_any_enrollment?

      # Unpayable if this was a phone/video call where the client wasn't reached
      reasons << :call_not_reached if @qa.reached_client == 'no' && ['phone_call', 'video_call'].include?(@qa.mode_of_contact)

      reasons << :limit_per_day unless @qa.within_per_day_limits?

      # Signing a care plan is payable regardless of engagement status
      return reasons if @qa.activity == 'pctp_signed'

      patient = @qa.patient
      date_of_activity = @qa.date_of_activity
      # Outreach is limited by the outreach cut-off date, enrollment ranges, and frequency
      if @qa.outreach?
        reasons << :outreach_past_cutoff if @qa.date_of_activity > patient.outreach_cutoff_date
        reasons << :outside_enrollment unless patient.contributed_dates.include?(date_of_activity)
        reasons << :limit_outreaches_per_month_exceeded unless @qa.first_outreach_of_month_for_patient?
        reasons << :limit_months_outreach_exceeded if @qa.number_of_outreach_activity_months > 3
      else
        # Non-outreach activities are payable at 1 per month before engagement unless there is a care-plan
        unless @qa.patient_has_signed_careplan?
          reasons << :limit_activities_per_month_without_careplan_exceeded unless @qa.first_non_outreach_of_month_for_patient?
          reasons << :activity_outside_of_engagement_without_careplan if patient.engagement_date.blank? || date_of_activity > patient.engagement_date
          reasons << :limit_months_without_careplan_exceeded if @qa.number_of_non_outreach_activity_months > 5
        end
      end

      reasons.uniq
    end
  end
end
