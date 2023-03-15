###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Stateless, QA data lives in associated model
module Health
  class QualifyingActivityV1
    include Health::VersionedQualifyingActivity

    FACE_TO_FACE_KEYS = [
      :in_person,
    ].freeze

    EFFECTIVE_DATE_RANGE = (.. '2023-03-31'.to_date).freeze

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
        },
        cha: {
          title: 'Comprehensive Health Assessment',
          code: 'G0506',
          weight: 10,
          hidden: true,
        },
        care_planning: {
          title: 'Care planning',
          code: 'T2024',
          weight: 20,
          hidden: true,
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
          title: 'Follow-up from inpatient hospital discharge (with client)',
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
          hidden: true,
        },
        intake_completed: {
          title: 'Intake/Reassessment (completing consent/ROI, CHA, SSM, care plan)',
          code: 'G9005',
          weight: 110,
        },
      }.sort_by { |_, m| m[:weight] }.to_h
    end
  end
end
