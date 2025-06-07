# frozen_string_literal: true

require 'rails_helper'
require 'connection_pool'
require 'redis'
require 'webmock/rspec'

RSpec.describe ApplicationNotifier do
  let(:url) { 'https://hooks.slack.com/services/test' }

  describe '#ping' do
    it 'logs and posts message' do
      notifier = described_class.new(url)
      stub_request(:post, url)
      expect(Rails.logger).to receive(:info).with('msg')
      notifier.ping('msg')
      expect(WebMock).to have_requested(:post, url)
    end
  end
end
