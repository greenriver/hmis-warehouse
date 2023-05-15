###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class AcHmis::VoidReferralRequest < CleanBaseMutation
    description 'Void a referral request'

    argument :referral_request_id, ID, required: true

    field :record, [Types::HmisSchema::ReferralRequest], null: true

    def resolve(referral_request_id:)
      return error_out('connection not configured') unless HmisExternalApis::AcHmis::LinkApi.enabled?

      request = HmisExternalApis::AcHmis::ReferralRequest.active
        .viewable_by(current_user)
        .find_by(referral_request_id: referral_request_id)
      return error_out('record not found') unless request

      errors.add :base, :server_error, full_message: 'not found' unless request
      return { errors: errors } if errors.any?

      project = Hmis::Hud::Project.viewable_by(current_user).find(request.project_id)
      return error_out('record not found') unless project

      allowed = current_user.permissions_for?(project, [:can_manage_incoming_referrals])
      return error_out('record not found') unless allowed

      begin
        HmisExternalApis::AcHmis::VoidReferralRequestJob.perform_now(
          referral_request: request,
          voided_by: current_user,
        )
      rescue StandardError => e
        return error_out(e.message) unless allowed
      end

      {
        record: request,
      }
    end

    protected

    def error_out(msg)
      errors = HmisErrors::Errors.new
      errors.add :base, :server_error, full_message: msg
      { errors: errors }
    end
  end
end
