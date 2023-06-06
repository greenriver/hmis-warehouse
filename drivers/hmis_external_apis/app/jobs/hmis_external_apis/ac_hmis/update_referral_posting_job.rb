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

    VALID_STATUS_IDS = HmisExternalApis::AcHmis::ReferralPosting.statuses.values_at(:closed_status, :accepted_pending_status, :denied_pending_status, :accepted_status, :denied_status).to_set

    # @param posting_id [Integer]  HmisExternalApis::AcHmis::ReferralPosting.identifier
    # @param posting_status_id [Integer] new status
    # @param requested_by [String]
    # @param referral_result_id [Integer] Only for denials. Value from HUD list 4.20.D.
    # @param denied_reason_id [Integer] required when Posting status is Denied Pending
    # @param denied_reason_text [String]
    # @param status_note [String]
    # @param contact_date [String] required when Posting status is Denied Pending or Accepted Pending
    def perform(posting_id:, posting_status_id:, requested_by:, denied_reason_id: nil, denied_reason_text: nil, status_note: nil, contact_date: nil, referral_result_id: nil)
      raise 'Invalid status. Expected one of: [Closed(13), AcceptedPending(18), DeniedPending(19), Accepted(20), Denied(21)]' unless VALID_STATUS_IDS.include?(posting_status_id)

      payload = {
        posting_id: posting_id,
        posting_status_id: posting_status_id,
        referral_result_id: referral_result_id,
        denied_reason_id: denied_reason_id,
        denied_reason_text: denied_reason_text,
        status_note: status_note,
        contact_date: format_date(contact_date),
        requested_by: requested_by,
      }.filter { |_, v| v.present? }

      payload[:denied_reason_id] = denied_reason_id if denied_reason_id

      response = link.update_referral_posting_status(payload)
      posting_attrs = response.parsed_body.fetch('postings').map { |h| h.transform_keys(&:underscore) }
      update_referral_postings(posting_attrs)
    end

    protected

    # we may get references to postings that are do not belong to the updated referral
    def posting_scope
      HmisExternalApis::AcHmis::ReferralPosting
    end

    def update_referral_postings(posting_attrs)
      # build lookup tables for entities referenced in postings; avoid n+1 queries
      postings_by_identifier = posting_attrs
        .map { |h| h.fetch('posting_id') }
        .compact_blank
        .then do |ids|
          posting_scope.where(identifier: ids).index_by(&:identifier)
        end
      posting_attrs.map do |attrs|
        posting_id = attrs.fetch('posting_id')
        posting = postings_by_identifier[posting_id]
        posting.status = attrs.fetch('posting_status_id')
        posting.save!
        posting
      end
    end
  end
end
