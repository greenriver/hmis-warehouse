###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Stateless, QA data lives in associated model
module Health
  class QualifyingActivityV2
    include Health::VersionedQualifyingActivity

    FACE_TO_FACE_KEYS = [
      :in_person,
    ].freeze

    EFFECTIVE_DATE_RANGE = ('2023-04-01'.to_date ..).freeze

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
        # verbal: {
        #   title: 'Verbal',
        #   code: 'U3',
        #   weight: 40,
        # },
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
        # group: {
        #   title: 'Group session',
        #   code: 'HQ',
        #   weight: 10,
        # },
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
        },
        cha: {
          title: 'Comprehensive Assessment',
          code: 'G0506',
          weight: 10,
          hidden: true,
        },
        cha_completed: {
          title: 'Comprehensive Assessment completed',
          code: 'G0506>U4',
          weight: 15,
          hidden: true,
        },
        care_planning: {
          title: 'Development of Care Plan',
          code: 'T2024',
          weight: 20,
          hidden: true,
        },
        care_coordination: {
          title: 'Care coordination',
          code: 'G9005',
          weight: 30,
        },
        care_team: {
          title: 'Meeting with 3+ care team members',
          code: 'G9007',
          weight: 40,
        },
        care_transitions: {
          title: 'Emergency Department visit (7 days)',
          code: 'T2038',
          weight: 45,
        },
        discharge_follow_up: {
          title: 'Follow-up from inpatient discharge with client (7 days)',
          code: 'T2038>U5',
          weight: 50,
        },
        pctp_signed: {
          title: 'Care Plan completed',
          code: 'T2024>U4',
          weight: 100,
          hidden: true,
        },
        intake_completed: {
          title: 'Intake/reassessment (completing consent ROI, comprehensive assessment, care plan)',
          code: 'G9005',
          weight: 110,
        },
        sdoh_positive: {
          title: 'SDoH screening positive',
          code: 'G9919',
          weight: 200,
        },
        sdoh_negative: {
          title: 'SDoH screening negative',
          code: 'G9920',
          weight: 210,
        },
      }.sort_by { |_, m| m[:weight] }.to_h
    end
  end
end
