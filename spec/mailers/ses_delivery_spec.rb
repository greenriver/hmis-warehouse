###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# Guards the ActionMailer/SES wiring that moved out of aws-sdk-rails into
# aws-actionmailer-ses. The SES client is stubbed, so nothing reaches AWS.
RSpec.describe 'SES delivery', type: :mailer do
  # Credentials and region are explicit so the spec does not depend on whatever
  # Aws.config the suite happens to carry.
  let(:ses_client) do
    Aws::SES::Client.new(
      stub_responses: true,
      region: 'us-east-1',
      credentials: Aws::Credentials.new('stubbed-akid', 'stubbed-secret'),
    ).tap do |client|
      client.stub_responses(:send_raw_email, message_id: 'stubbed-message-id')
    end
  end
  let(:mailer) { Aws::ActionMailer::SES::Mailer.new(ses_client: ses_client) }
  let(:request) { ses_client.api_requests.first }
  let(:mail) do
    Mail.new do
      from 'noreply@openpath.host'
      to 'someone@example.org'
      subject 'SES delivery spec'
      body 'hello'
    end
  end

  it 'registers the SES delivery methods with ActionMailer' do
    expect(ActionMailer::Base.delivery_methods[:ses]).to eq(Aws::ActionMailer::SES::Mailer)
    expect(ActionMailer::Base.delivery_methods[:ses_v2]).to eq(Aws::ActionMailer::SESV2::Mailer)
  end

  describe 'delivering a message' do
    before { mailer.deliver!(mail) }

    it 'sends through the SES raw email API' do
      expect(request[:operation_name]).to eq(:send_raw_email)
    end

    it 'takes the source and destinations from the envelope' do
      expect(request[:params][:source]).to eq('noreply@openpath.host')
      expect(request[:params][:destinations]).to eq(['someone@example.org'])
    end

    it 'records the SES message id on the message' do
      expect(mail.header[:ses_message_id].value).to eq('stubbed-message-id')
    end
  end

  # SES reads the configuration set off a header rather than an API parameter,
  # so it only applies if CloudwatchEmailInterceptor's headers survive into the
  # raw message the mailer sends.
  describe 'CloudwatchEmailInterceptor headers' do
    let(:raw_message) { request[:params][:raw_message][:data] }

    before do
      CloudwatchEmailInterceptor.delivering_email(mail)
      mailer.deliver!(mail)
    end

    it 'carries the SES configuration set' do
      expect(raw_message).to include("X-SES-CONFIGURATION-SET: #{ENV.fetch('SES_CONFIG_SET') { 'OpenPathConfigSet' }}")
    end

    it 'carries the remaining SES tracking headers' do
      expect(raw_message).to include('X-SES-APP: Warehouse')
      expect(raw_message).to include("X-SES-ENVIRONMENT: #{Rails.env}")
    end
  end
end
