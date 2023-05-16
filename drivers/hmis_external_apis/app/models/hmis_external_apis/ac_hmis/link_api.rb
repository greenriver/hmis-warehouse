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
