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

    def self.enabled?
      ::GrdaWarehouse::RemoteCredential.active.where(slug: SYSTEM_ID).exists?
    end

    def create_referral_request(payload)
      conn.post('Referral/ReferralRequest', payload)
        .then { |r| handle_error(r) }
    end

    def void_referral_request(id:, **payload)
      conn.patch("Referral/ReferralRequest/#{id}", payload)
        .then { |r| handle_error(r) }
    end

    protected

    def handle_error(result)
      raise HmisErrors::ApiError, result.error if result.error

      result
    end

    def creds
      @creds ||= ::GrdaWarehouse::RemoteCredential.active.where(slug: SYSTEM_ID).first!
    end

    def conn
      @conn ||= HmisExternalApis::OauthClientConnection.new(
        client_id: creds.client_id,
        client_secret: creds.client_secret,
        token_url: creds.token_url,
        base_url: creds.base_url,
        headers: creds.additional_headers,
        scope: creds.oauth_scope,
      )
    end
  end
end
