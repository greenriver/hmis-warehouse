###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::ReferralPostingDenialReasonType < Types::BaseEnum
    description 'Referral Posting Denial Reason'
    graphql_name 'ReferralPostingDenialReasonType'

    value 'HMISUserError', 'HMIS user error', value: 20
    value 'InabilityToCompleteIntake', 'Inability to complete intake', value: 21
    value 'DoesNotMeetEligibilityCriteria', 'Does not meet eligibility criteria', value: 22
    value 'NoLongerInterestedInThisProgram', 'No longer interested in this program', value: 23
    value 'NoLongerExperiencingHomelessness', 'No longer experiencing homelessness', value: 24
    value 'EstimatedVacancyNoLongerAvailable', 'Estimated vacancy no longer available', value: 25
    value 'EnrolledButDeclinedHMISDataEntry', 'Enrolled, but declined HMIS data entry', value: 26
  end
end
