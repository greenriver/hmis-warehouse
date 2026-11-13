###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

#####
# DEPRECATED 🚨
# The LinkApi class has been deprecated. Its only remaining method,
# update_referral_posting_status, is still in active use for legacy ReferralPostings
# and will be removed once all legacy postings have been worked through (#8142).
#
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
####
module HmisExternalApis::AcHmis
  class LinkApi
    SYSTEM_ID = 'ac_hmis_link'
    CONNECTION_TIMEOUT_SECONDS = 10
    Error = HmisErrors::ApiError.new(display_message: 'Failed to connect to LINK')

    def self.enabled?
      ::GrdaWarehouse::RemoteCredential.active.where(slug: SYSTEM_ID).exists?
    end

    # NOTE: Not yet deprecated - This method is still in active use for updating posting status
    # on legacy ReferralPostings. It will be deprecated once all legacy postings have been worked through.
    def update_referral_posting_status(payload)
      conn.patch('Referral/PostingStatus', format_payload(payload, id_variant: 'Id')).
        then { |r| handle_error(r) }
    end

    def with_logger(logger)
      last_logger = conn.logger
      result = nil
      begin
        conn.logger = logger
        result = yield
      ensure
        conn.logger = last_logger
      end
      result
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
