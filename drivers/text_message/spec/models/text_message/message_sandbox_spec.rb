###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TextMessage::Message, type: :model do
  let(:topic) { TextMessage::Topic.create!(title: 'Reminders', arn: 'arn:aws:sns:us-east-1:000000000000:reminders') }
  let(:subscriber) { TextMessage::TopicSubscriber.create!(topic: topic, phone_number: '5555550123') }
  let(:message) { described_class.create!(topic: topic, topic_subscriber: subscriber, content: 'Hello', send_on_or_after: Date.current) }
  let(:sns_client) do
    instance_double(
      Aws::SNS::Client,
      check_if_phone_number_is_opted_out: double(is_opted_out: false),
      publish: nil,
    )
  end

  before do
    allow(message).to receive(:sns_client).and_return(sns_client)
    allow(message).to receive(:sleep)
  end

  describe '#send!' do
    it 'publishes once and records the send outside sandbox mode' do
      message.send!

      expect(sns_client).to have_received(:publish).with(phone_number: '15555550123', message: 'Hello').once
      expect(message.reload.sent_at).to be_present
    end

    it 'publishes nothing and leaves the message unsent in sandbox mode' do
      with_sandbox_mode { message.send! }

      expect(sns_client).not_to have_received(:publish)
      expect(message.reload.sent_at).to be_nil
    end
  end

  describe '#test!' do
    it 'raises and publishes nothing in sandbox mode' do
      with_sandbox_mode do
        expect { message.test!('5555550123') }.to raise_error(SandboxMode::IntegrationDisabled, 'SMS is disabled in sandbox mode')
      end

      expect(sns_client).not_to have_received(:publish)
    end
  end
end
