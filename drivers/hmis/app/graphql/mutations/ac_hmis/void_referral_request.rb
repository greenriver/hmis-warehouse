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
      return error_response('connection not configured') unless HmisExternalApis::AcHmis::LinkApi.enabled?

      request = HmisExternalApis::AcHmis::ReferralRequest.active
        .viewable_by(current_user)
        .find_by(id: referral_request_id)
      return error_response('referral request record not found') unless request

      project = Hmis::Hud::Project.viewable_by(current_user).find(request.project_id)
      return error_response('project record not found') unless project

      allowed = current_user.can_manage_incoming_referrals_for?(project)
      return error_response('access denied') unless allowed

      begin
        HmisExternalApis::AcHmis::VoidReferralRequestJob.perform_now(
          referral_request: request,
          voided_by: current_user,
        )
      rescue HmisErrors::ApiError => e
        return error_response(e.message)
      end

      {
        record: request,
      }
    end

    protected

    def error_response(msg)
      errors = HmisErrors::Errors.new
      errors.add :base, :server_error, full_message: msg
      { errors: errors }
    end
  end
end
