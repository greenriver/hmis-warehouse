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

    value 'HMISUserError', 'HMIS user error', value: 1
    value 'InabilityToCompleteIntake', 'Inability to complete intake', value: 2
    value 'DoesNotMeetEligibilityCriteria', 'Does not meet eligibility criteria', value: 3
    value 'NoLongerInterestedInThisProgram', 'No longer interested in this program', value: 4
    value 'NoLongerExperiencingHomelessness', 'No longer experiencing homelessness', value: 5
    value 'EstimatedVacancyNoLongerAvailable', 'Estimated vacancy no longer available', value: 6
    value 'EnrolledButDeclinedHMISDataEntry', 'Enrolled, but declined HMIS data entry', value: 7
  end
end
