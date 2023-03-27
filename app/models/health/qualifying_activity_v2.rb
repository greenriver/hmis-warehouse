###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Stateless, QA data lives in associated model
module Health
  class QualifyingActivityV2 < QualifyingActivityBase
    FACE_TO_FACE_KEYS = [
      :in_person,
    ].freeze

    CONTACTLESS_ACTIVITIES = [:cha_completed, :pctp_signed, :sdoh_positive, :sdoh_negative].freeze

    EFFECTIVE_DATE_RANGE = ('2023-04-01'.to_date ..).freeze
    ATTRIBUTE_SUFFIX = '_v2'.freeze

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
          code: '95',
          weight: 30,
        },
        text_message: {
          title: 'Text messaging',
          code: 'U3',
          weight: 35,
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

    # Outreach for enrollment
    # Care coordination
    # Meeting with 3+ care team members
    # Intake/reassessment (completing consent ROI, comprehensive assessment, care plan)
    # Follow-up from inpatient discharge with client (7 days)
    # Emergency Department visit (7 days)
    def self.activities
      @activities ||= {
        outreach: {
          title: 'Outreach for enrollment',
          code: 'G9011',
          weight: 0,
          allowed: ['U1', 'UK', 'U2', 'U3', '95'],
          required: [],
          per_day: 3,
        },
        cha: {
          title: 'Comprehensive Assessment',
          code: 'G0506',
          weight: 10,
          hidden: true,
          allowed: ['U1', 'UK', 'U2'],
          required: [],
          per_day: 1,
        },
        cha_completed: {
          title: 'Comprehensive Assessment completed',
          code: 'G0506>U4',
          weight: 15,
          hidden: true,
          allowed: [],
          required: ['U4'],
          per_day: 1,
        },
        care_planning: {
          title: 'Development of Care Plan',
          code: 'T2024',
          weight: 20,
          hidden: true,
          allowed: ['U1', 'UK', 'U2', 'U3', '95'],
          required: [],
          per_day: 3,
        },
        care_coordination: {
          title: 'Care coordination',
          code: 'G9005',
          weight: 30,
          allowed: ['U1', 'UK', 'U2', 'U3', '95'],
          required: [],
          per_day: 4,
        },
        care_team: {
          title: 'Meeting with 3+ care team members',
          code: 'G9007',
          weight: 40,
          allowed: ['U1', 'U2', 'U3', '95'],
          required: [],
          per_day: 1,
        },
        care_transitions: {
          title: 'Emergency Department visit (7 days)',
          code: 'T2038',
          weight: 45,
          allowed: ['U1', 'U2', 'U3', '95'],
          required: [],
          per_day: 2,
        },
        discharge_follow_up: {
          title: 'Follow-up from inpatient discharge with client (7 days)',
          code: 'T2038>U5',
          weight: 50,
          allowed: ['U1', 'U2'],
          required: ['U5'],
          per_day: 2,
        },
        pctp_signed: {
          title: 'Care Plan completed',
          code: 'T2024>U4',
          weight: 100,
          hidden: true,
          allowed: [''],
          required: ['U4'],
          per_day: 1,
        },
        intake_completed: {
          title: 'Intake/reassessment (completing consent ROI, comprehensive assessment, care plan)',
          code: 'G9005',
          weight: 110,
          allowed: ['U1', 'UK', 'U2', 'U3', '95'],
          required: [],
          per_day: 4,
        },
        sdoh_positive: {
          title: 'SDoH screening positive',
          code: 'G9919',
          weight: 200,
          allowed: [],
          required: [],
          per_day: 1,
        },
        sdoh_negative: {
          title: 'SDoH screening negative',
          code: 'G9920',
          weight: 210,
          allowed: [],
          required: [],
          per_day: 1,
        },
      }.sort_by { |_, m| m[:weight] }.to_h
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

      reasons.uniq
    end
  end
end
