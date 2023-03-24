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
        },
        care_planning: {
          title: 'Care planning',
          code: 'T2024',
          weight: 20,
          hidden: true,
          allowed: ['U1', 'U2', 'U3', 'UK'],
          required: [],
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
        },
        referral_to_aco: {
          title: 'Referral to ACO for Flexible Services',
          code: 'T1023>U6',
          weight: 90,
          allowed: ['U1', 'U2', 'U3'],
          required: ['U6'],
        },
        pctp_signed: {
          title: 'Person-Centered Treatment Plan signed',
          code: 'T2024>U4',
          weight: 100,
          hidden: true,
          allowed: ['U1', 'U2', 'UK'],
          required: ['U4'],
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

    def modifiers(qa)
      modifiers = []

      # COVID rules permitted remote contacts to be treated as in-person,
      # these rules ended with the end of the first CP program
      contact_modifier = case qa.activity&.to_sym
      when :cha, :discharge_follow_up
        if [:phone_call, :video_call].include?(qa.mode_of_contact&.to_sym)
          modes_of_contact[:in_person][:code]
        else
          modes_of_contact[qa.mode_of_contact&.to_sym].try(:[], :code)
        end
      else
        modes_of_contact[qa.mode_of_contact&.to_sym].try(:[], :code)
      end

      # attach modifiers from activity
      modifiers << activities[qa.activity&.to_sym].try(:[], :code)&.split(' ').try(:[], 1)

      modifiers << contact_modifier
      modifiers << client_reached[qa.reached_client&.to_sym].try(:[], :code)

      return modifiers.reject(&:blank?).compact
    end
  end
end
