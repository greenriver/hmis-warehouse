###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

# CAUTION: This is not part of the normal test suite. It runs against a live remote endpoint
# We need many secrets to test this. Essentially, this runs locally or on staging
# The intention is to check if the remote side is behaving as we expect, rather than to test
# our own implementation
RSpec.describe 'LINK API', type: :model do
  if ENV['OAUTH_CREDENTIAL_TEST'] == 'true'
    let(:creds) do
      create(
        :grda_remote_oauth_credential,
        client_id: ENV.fetch('LINK_CLIENT_ID'),
        client_secret: ENV.fetch('LINK_CLIENT_SECRET'),
        token_url: ENV.fetch('LINK_TOKEN_URL'),
        additional_headers: { 'Ocp-Apim-Subscription-Key' => ENV.fetch('LINK_OCP_APIM_SUBSCRIPTION_KEY') },
        base_url: ENV.fetch('LINK_BASE_URL') + '/',
        oauth_scope: 'GREEN_RIVER',
      )
    end

    let(:requested_by) { 'test@greenriver.com' }
    let(:now) { Time.now }
    let(:program_id) { 1008 }
    let(:unit_type_id) { 32 }

    def format_date(date)
      date.to_s(:iso8601)
    end

    let(:subject) do
      HmisExternalApis::OauthClientConnection.new(creds)
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

    # this test is not repeatable - statuses can only be used once for each posting
    # it 'updates referral posting status' do
    #   payload = {
    #     'postingId' => 786930,
    #     'postingStatusId' => 18,
    #     'deniedReasonId' => nil,
    #     'referralResultId' => nil,
    #     'statusNote' => 'test',
    #     'contactDate' => format_date(now),
    #     'requestedBy' => 'test@greenriver.com',
    #   }

    #   result = subject.patch('Referral/PostingStatus', payload)
    #   # Note: PostingStatus/ID doesn't work
    #   # {"status":400,"body":{"message":"Posting Status Id is not valid. ","detail":"Invalid Parameters."}
    #   log_request(name: 'update_referral_posting_status', result: result)
    #   expect(result.http_status).to eq(200)
    # end

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
