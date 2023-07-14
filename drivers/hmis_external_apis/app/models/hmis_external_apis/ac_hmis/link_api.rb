###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# To connect to the API, you need a remote credential for this endpoint. Replace
# the empty strings below with values from the documentation.
#
# creds = GrdaWarehouse::RemoteCredentials::Oauth.where(slug: 'ac_hmis_link').first_or_initialize
# creds.attributes = {
#   "active"=>true,
#   "client_id" => "00001111222223334445",
#   "client_secret" => "0000000000000000000000000000000000000000",
#   "oauth_scope"=>"API_TEST",
#   "token_url"=>"http://ac_hmis_stub:9292/oauth2/token",
#   "base_url"=>"http://ac_hmis_stub:9292/api",
#   "additional_headers"=>{'Ocp-Apim-Subscription-Key': 'abcdeTest'},
# }

module HmisExternalApis::AcHmis
  class LinkApi
    SYSTEM_ID = 'ac_hmis_link'.freeze
    CONNECTION_TIMEOUT_SECONDS = Rails.env.staging? ? 10 : 5
    Error = HmisErrors::ApiError.new(display_message: 'Failed to connect to LINK')

    def self.enabled?
      ::GrdaWarehouse::RemoteCredential.active.where(slug: SYSTEM_ID).exists?
    end

    def create_referral_request(payload)
      conn.post('Referral/ReferralRequest', format_payload(payload))
        .then { |r| handle_error(r) }
    end

    def void_referral_request(referral_request_id:, requested_by:)
      payload = format_payload({ is_void: true, requested_by: requested_by })
      conn.patch("Referral/ReferralRequest/#{referral_request_id}", payload)
        .then { |r| handle_error(r) }
    end

    def update_unit_capacity(payload)
      conn.patch('Unit/Capacity', format_payload(payload))
        .then { |r| handle_error(r) }
    end

    def update_referral_posting_status(payload)
      conn.patch('Referral/PostingStatus', format_payload(payload, id_variant: 'Id'))
        .then { |r| handle_error(r) }
    end

    def active_referral_mci_ids
      conn.get('Referral/ActiveReferralMciid').then { |r| handle_error(r) }
    end

    protected

    def handle_error(result)
      Rails.logger.error "LINK Error: #{result.error}" if result.error
      Sentry.capture_exception(StandardError.new(result.error)) if result.error
      raise(Error, result.error) if result.error

      result
    end

    def creds
      @creds ||= ::GrdaWarehouse::RemoteCredential.active.where(slug: SYSTEM_ID).first!
    end

    def conn
      @conn ||= HmisExternalApis::OauthClientConnection.new(creds, connection_timeout: CONNECTION_TIMEOUT_SECONDS)
    end

    # @param payload [Hash]
    # @param id_variant [String] account for inconsistent casing in external API (Id vs ID)
    def format_payload(payload, id_variant: 'ID')
      payload.transform_keys { |k| format_key_name(k, id_variant) }
    end

    def format_key_name(key, id_variant)
      key.to_s.camelize(:lower).gsub(/Id\z/, id_variant)
    end
  end
end
