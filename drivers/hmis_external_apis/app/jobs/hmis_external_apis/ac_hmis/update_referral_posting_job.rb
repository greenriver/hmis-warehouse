###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# An HMIS User changes the status of a Posting, for example accepting/rejecting/denying
# a household into a program/project

# The following "new statuses" are allowed to be sent.
# For example, a posting that was in Assigned status
# is allowed to be changed to "AcceptedPending" OR "DeniedPending"
#
# ---------------------------------------------------
# New Status             | Old Status
# ---------------------------------------------------
# Closed(13)             | Accepted(20), Denied(21)
# AcceptedPending(18)    | Assigned(12)
# DeniedPending(19)      | Assigned(12), AcceptedPending(18)
# Accepted(20)           | AcceptedPending(18)
# Denied(21)             | DeniedPending(19)
# Accepted(20)           | Closed(13)

module HmisExternalApis::AcHmis
  class UpdateReferralPostingJob < ApplicationJob
    include HmisExternalApis::AcHmis::ReferralJobMixin

    VALID_STATUS_IDS = HmisExternalApis::AcHmis::ReferralPosting::VALID_LOCAL_STATUS_IDS

    # @param posting_id [Integer]  HmisExternalApis::AcHmis::ReferralPosting.identifier
    # @param posting_status_id [Integer] new status
    # @param requested_by [String]
    # @param referral_result_id [Integer] Only for denials. Value from HUD list 4.20.D.
    # @param denied_reason_id [Integer] required when Posting status is Denied Pending
    # @param denied_reason_text [String]
    # @param status_note [String]
    # @param contact_date [String] required when Posting status is Denied Pending or Accepted Pending
    def perform(posting_id:, posting_status_id:, requested_by:, denied_reason_id: nil, denial_note: nil, status_note: nil, contact_date: nil, referral_result_id: nil)
      raise "Invalid status. Expected one of: [#{VALID_STATUS_IDS.inspect}]" unless VALID_STATUS_IDS.include?(posting_status_id)

      payload = {
        posting_id: posting_id,
        posting_status_id: posting_status_id,
        referral_result_id: referral_result_id,
        denied_reason_id: denied_reason_id,
        denial_notes: denial_note,
        status_note: status_note,
        contact_date: format_date(contact_date),
        requested_by: format_requested_by(requested_by),
      }.compact_blank

      link.update_referral_posting_status(payload)
    end
  end
end
