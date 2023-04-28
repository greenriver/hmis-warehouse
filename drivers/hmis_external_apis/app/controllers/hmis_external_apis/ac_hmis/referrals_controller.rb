###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis
  class ReferralsController < HmisExternalApis::BaseController
    MAX_SIZE = 1_024_000
    def create
      # Unfortunately the referral isn't contained in top-level object
      # so get the params before rails pollutes it
      if request.raw_post.bytesize > MAX_SIZE
        msg = "Request is too large, maximum is #{MAX_SIZE.to_s(:human_size)}"
        return respond_with_errors([msg])
      end
      unsafe_params = JSON.parse(request.raw_post)
      errors = validate_request(unsafe_params)
      return respond_with_errors(errors) if errors.any?

      (referral, errors) = HmisExternalApis::AcHmis::CreateReferralJob.perform_now(params: unsafe_params)
      return respond_with_errors(errors) if errors.any?

      render json: { message: 'Referral Created', id: referral.identifier }
    end

    protected

    def internal_system
      @internal_system ||= HmisExternalApis::InternalSystem.where(name: 'Referrals').first
    end

    def validate_request(data)
      schema_path = Rails.root
        .join('drivers/hmis_external_apis/public/schemas/referral.json')
      HmisExternalApis::JsonValidator.perform(data, schema_path)
    end
  end
end
