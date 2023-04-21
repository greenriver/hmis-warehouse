###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis
  class ReferralsController < BaseController
    before_action :authorize_request
    skip_before_action :authenticate_user!
    prepend_before_action :skip_timeout

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

      referral = HmisExternalApis::CreateReferralJob.perform_now(params: unsafe_params)
      render json: { message: 'Referral Created', id: referral.identifier }
    end

    protected

    def authorize_request
      # FIXME: token auth or oauth?
      raise unless Rails.env.development? || Rails.env.test?
    end

    def validate_request(data)
      schema_path = Rails.root
        .join('drivers/hmis_external_apis/public/schemas/referral.json')
      HmisExternalApis::JsonValidator.perform(data, schema_path)
    end

    # render a 400 with validation messages
    def respond_with_errors(errors)
      json = {
        message: 'JSON schema validation failure',
        errors: errors,
      }
      render(status: :bad_request, json: json)
    end
  end
end
