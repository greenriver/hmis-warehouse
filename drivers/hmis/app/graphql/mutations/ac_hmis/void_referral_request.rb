###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class AcHmis::VoidReferralRequest < CleanBaseMutation
    description 'Void a referral request'

    argument :referral_request_id, ID, required: true

    field :record, Types::HmisSchema::ReferralRequest, null: true

    def resolve(referral_request_id:)
      handle_error('connection not configured') unless HmisExternalApis::AcHmis::LinkApi.enabled?

      request = HmisExternalApis::AcHmis::ReferralRequest.active
        .viewable_by(current_user)
        .find_by(id: referral_request_id)
      handle_error('referral request not found') unless request

      allowed = current_user.can_manage_incoming_referrals_for?(request.project)
      handle_error('access denied') unless allowed

      HmisExternalApis::AcHmis::VoidReferralRequestJob.perform_now(
        referral_request: request,
        voided_by: current_user,
      )

      { record: request }
    end

    protected

    def handle_error(msg)
      raise msg
    end
  end
end
