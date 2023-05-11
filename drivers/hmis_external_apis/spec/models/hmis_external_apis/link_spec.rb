###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

# CAUTION: This is not part of the normal test suite. It runs against a live remote endpoint
# We need many secrets to test this. Essentially, this runs locally or on staging
RSpec.describe 'LINK API', type: :model do
  if ENV['OAUTH_CREDENTIAL_TEST'] == 'true'
    let(:base_url) { ENV.fetch('LINK_BASE_URL') + '/' }
    let(:client_id) { ENV.fetch('LINK_CLIENT_ID') }
    let(:client_secret) { ENV.fetch('LINK_CLIENT_SECRET') }
    let(:token_url) { ENV.fetch('LINK_TOKEN_URL') }
    let(:oauth_scope) { 'GREEN_RIVER' }
    let(:ocp_apim_subscription_key) { ENV.fetch('LINK_OCP_APIM_SUBSCRIPTION_KEY') }

    let(:requested_by) { 'test@greenriver.com' }
    let(:now) { Time.now }
    let(:program_id) { 1008 }
    let(:unit_type_id) { 32 }

    def format_date(date)
      date.to_s(:iso8601)
    end

    let(:subject) do
      HmisExternalApis::OauthClientConnection.new(
        client_id: client_id,
        client_secret: client_secret,
        token_url: token_url,
        headers: { 'Ocp-Apim-Subscription-Key' => ocp_apim_subscription_key },
        base_url: base_url,
        scope: oauth_scope,
      )
    end

    it 'creates referral request' do
      payload = {
        'requestedDate' => format_date(now),
        'programID' => program_id,
        'unitTypeID' => unit_type_id,
        'estimatedDate' => format_date(now + 1.week),
        'requestorName' => 'greenriver',
        'requestorPhoneNumber' => '8028675309',
        'requestorEmail' => requested_by,
        'requestedBy' => requested_by,
      }
      result = subject.post('Referral/ReferralRequest', payload)
      log_request(name: 'create_referral_request', result: result)
      expect(result.http_status).to eq(201)
    end

    it 'updates referral request' do
      payload = { 'isVoid' => true, 'requestedBy' => requested_by }

      result = subject.patch('Referral/ReferralRequest/60', payload)
      log_request(name: 'update_referral_request', result: result)
      expect(result.http_status).to eq(200)
    end

    it 'updates referral posting status' do
      payload = {
        'postingId' => 3777,
        'postingStatusId' => 21,
        'deniedReasonId' => 1,
        'referralResultId' => 158,
        'statusNote' => 'test',
        'contactDate' => format_date(now),
        'requestedBy' => requested_by,
      }
      result = subject.patch('Referral/PostingStatus', payload)
      # Note: PostingStatus/ID doesn't work
      # {"status":400,"body":{"message":"Posting Status Id is not valid. ","detail":"Invalid Parameters."}
      log_request(name: 'update_referral_posting_status', result: result)
      expect(result.http_status).to eq(200)
    end

    it 'updates unit capacity' do
      payload = {
        'programID' => program_id,
        'unitTypeID' => unit_type_id,
        'availableUnits' => 3,
        'requestedBy' => requested_by,
      }

      result = subject.patch('Unit/Capacity', payload)
      log_request(name: 'update_unit_capacity', result: result)
      expect(result.http_status).to eq(200)
    end

    # helpful for debugging
    def log_request(name:, result:)
      msg = {
        name: name,
        request: {
          url: result.url,
          method: result.http_method,
          body: result.request_body,
          headers: result.request_headers,
        },
        response: {
          status: result.http_status,
          body: result.error,
        },
      }
      msg[:request][:headers]['Authorization'] = 'redacted'
      path = Rails.root.join("link_log/#{name}.json")
      File.write(path, msg.to_json)
    end

  end
end
