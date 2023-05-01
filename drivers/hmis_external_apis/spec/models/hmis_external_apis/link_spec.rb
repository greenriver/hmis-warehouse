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

    let(:requested_by) { 'user1@example.com' }
    let(:now) { Time.now }
    let(:program_id) { 1072 }
    let(:unit_type_id) { 20 }

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
        'estimatedDate' => format_date(now + 1.day),
        'requestorName' => 'greenriver',
        'requestorPhoneNumber' => '8028675309',
        'requestorEmail' => 'test@greenriver.com',
        'requestedBy' => requested_by,
      }

      result = subject.post('Referral/ReferralRequest', payload)
      # {"message"=>"A server error occurred.", "detail"=>"ORA-00942: table or view does not exist", "errorReferenceId"=>"58e06257-3128-43d0-96fe-03cc6af4d8d6"}
      byebug unless result.http_status == 200
      expect(result.http_status).to eq(200)
    end

    it 'updates referral request' do
      payload = { 'isVoid' => true, 'requestedBy' => requested_by }

      result = subject.patch('Referral/ReferralRequest/60', payload)
      byebug unless result.http_status == 200
      # {"message"=>"A server error occurred.", "detail"=>"ORA-06550: line 1, column 7:\nPLS-00201: identifier 'HMIS.PC_GREEN_RIVER_API' must be declared\nORA-06550: line 1, column 7:\nPL/SQL: Statement ignored", "errorReferenceId"=>"6c7ac709-21a0-4e40-80f1-4adf400dcfe0"}
      expect(result.http_status).to eq(200)
    end

    it 'updates referral posting status' do
      payload = {
        "postingId": 2176,
        'postingStatusId' => 18,
        'deniedReasonId' => 1,
        'referralResultId' => 158,
        'statusNote' => 'test',
        'contactDate' => format_date(now),
        'requestedBy' => requested_by,
      }
      payload = {
        "postingStatusId": 18,
        "deniedReasonId": 1,
        "deniedReasonText": 'test',
        "statusNote": 'test',
        "contactDate": '2023-04-13T13:11:24.190Z',
        "requestedBy": 'GreenRiver',
      }

      # Note: PostingStatus/ID doesn't work
      # {"message"=>"Posting Id doesn't exist. Posting Status Id is not valid. ", "detail"=>"Invalid Parameters."}
      result = subject.patch('Referral/PostingStatus', payload)
      byebug unless result.http_status == 200
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
      byebug unless result.http_status == 200
      # {"message"=>"A server error occurred.", "detail"=>"ORA-00942: table or view does not exist", "errorReferenceId"=>"6f30d636-d276-40dc-ab3a-3e654ec4f431"}
      expect(result.http_status).to eq(200)
    end

  end
end
