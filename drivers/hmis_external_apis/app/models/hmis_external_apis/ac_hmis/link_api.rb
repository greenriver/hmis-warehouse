###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# To connect to the API, you need a remote credential for this endpoint. Replace
# the empty strings below with values from the documentation.
#
#  creds = GrdaWarehouse::RemoteCredentials::Oauth.where(slug: 'ac_hmis_link').first_or_initialize
#
#  creds.client_id = ''
#  creds.client_secret = ''
#  creds.oauth_scope = 'API_TEST'
#  creds.token_url = ''
#  creds.base_url = ''
#  creds.additional_headers = {
#    'Ocp-Apim-Subscription-Key' => ''
#  }

module HmisExternalApis::AcHmis
  class LinkApi
    LINK_ID = 'ac_hmis_link'.freeze
    Error = StandardError.new

    def creds
      @creds ||= ::GrdaWarehouse::RemoteCredential.active.where(slug: LINK_ID).first!
    end

    def create_referral_request(payload)
      conn.post('Referral/ReferralRequest', payload)
        .then { |r| JSON.parse(r.body) }
    end

    def conn
      @conn ||=
        OauthClientConnection.new(
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
