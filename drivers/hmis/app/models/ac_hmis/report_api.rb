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
#   "id"=>6,
#   "type"=>"GrdaWarehouse::RemoteCredentials::Oauth",
#   "active"=>true,
#   "username"=>"",
#   "encrypted_password"=>"",
#   "encrypted_password_iv"=>nil,
#   "region"=>nil,
#   "bucket"=>"API_TEST",
#   "path"=>"https://alleghenycounty-demo.oktapreview.com/oauth2/TOKEN/v1/token",
#   "endpoint"=>"https://BASE/green-river-api/api",
#   "created_at"=>Thu, 07 Dec 2023 16:33:49.435762000 EST -05:00,
#   "updated_at"=>Thu, 07 Dec 2023 16:33:49.435762000 EST -05:00,
#   "deleted_at"=>nil,
#   "additional_headers"=>{"Ocp-Apim-Subscription-Key"=>""},
#   "slug"=>"ac_reports",
#   "password"=>nil
# }

module AcHmis
  class ReportApi
    SYSTEM_ID = 'ac_reports'.freeze
    CONNECTION_TIMEOUT_SECONDS = 60
    Error = HmisErrors::ApiError.new(display_message: 'Failed to connect to LINK Reports')

    def self.enabled?
      GrdaWarehouse::RemoteCredentials::Oauth.active.where(slug: SYSTEM_ID).exists?
    end

    def prevention_assessment_report(referral_id:)
      conn.get("Reports/PreventionAssessment/#{referral_id}").then { |r| handle_error(r) }
    end

    protected

    def handle_error(result)
      Rails.logger.error "LINK Reports Error: #{result.error}" if result.error
      Sentry.capture_exception(StandardError.new(result.error)) if result.error
      raise(Error, result.error) if result.error

      result
    end

    def creds
      @creds = GrdaWarehouse::RemoteCredentials::Oauth.find_by(slug: SYSTEM_ID)
    end

    def conn
      raise 'HmisExternalApis driver is not loaded' unless RailsDrivers.loaded.include?(:hmis_external_apis)

      @conn ||= HmisExternalApis::OauthClientConnection.new(creds, connection_timeout: CONNECTION_TIMEOUT_SECONDS)
    end
  end
end
