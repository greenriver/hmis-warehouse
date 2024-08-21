###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis
  class ReferralsController < HmisExternalApis::BaseController
    MAX_SIZE = 1_024_000
    def create
      # Create request log
      request_log

      # Unfortunately the referral isn't contained in top-level object
      # so get the params before rails pollutes it
      if request.raw_post.bytesize > MAX_SIZE
        msg = "Request is too large, maximum is #{MAX_SIZE.to_fs(:human_size)}"
        request_log.update!(request: 'too large') # Don't store large request
        return respond_with_errors([msg])
      end

      unsafe_params = JSON.parse(request.raw_post)
      unsafe_params = deep_compact(unsafe_params)
      errors = validate_request(unsafe_params)
      return respond_with_errors(errors) if errors.any?

      (referral, errors) = HmisExternalApis::AcHmis::CreateReferralJob.perform_now(params: unsafe_params)
      return respond_with_errors(errors) if errors.any?

      json = { message: referral.identifier_previously_changed? ? 'Referral Created' : 'Referral Found', id: referral.identifier }
      request_log.update!(response: json, http_status: 200)
      render json: json
    rescue JSON::ParserError => e
      return respond_with_errors(e.message)
    end

    protected

    def internal_system
      @internal_system ||= HmisExternalApis::InternalSystem.where(name: 'Referrals').first
    end

    def validate_request(data)
      schema_path = Rails.root.
        join('drivers/hmis_external_apis/public/schemas/referral.json')
      HmisExternalApis::JsonValidator.perform(data, schema_path)
    end

    # Recursively remove keys with null values or empty string values
    def deep_compact(hash)
      res_hash = hash.map do |key, value|
        value = deep_compact(value) if value.is_a?(Hash)
        value = value.map { |a| deep_compact(a) } if value.is_a?(Array) && value[0].is_a?(Hash)

        [key, value]
      end

      res_hash.to_h.filter { |_, v| v.to_s.present? }
    end
  end
end
