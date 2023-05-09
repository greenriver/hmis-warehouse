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

module HmisExternalApis::AcHmis
  class UpdateReferralPostingJob < ApplicationJob
    include HmisExternalApis::AcHmis::ReferralJobMixin

    # @param identifier [String]  HmisExternalApis::AcHmis::ReferralPosting.identifier
    # @param status [Integer] new status
    # @param referral_result [Integer] Only for denials. Value from HUD list 4.20.D.
    # @param url [String]
    def perform(identifier:, status:, url:, referral_result: nil)
      raise 'Invalid status. Expected one of: [Closed(13), AcceptedPending(18), DeniedPending(19), Accepted(20), Denied(21)]' unless [13, 18, 19, 20, 21].include?(status)

      payload = {
        posting_id: identifier,
        posting_status: status,
      }
      payload[:referral_result] = referral_result if referral_result

      response = post_referral_request(url, payload)
      update_referral_postings(response.fetch('postings'))
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
        .compact
        .then do |ids|
          ids.any? ? posting_scope.where(identifier: ids).index_by(&:identifier) : {}
        end
      posting_attrs.map do |attrs|
        posting_id = attrs.fetch('posting_id')

        posting = postings_by_identifier[posting_id]
        posting.status = attrs.fetch('posting_status')
        posting.save!
        posting
      end
    end
  end
end
