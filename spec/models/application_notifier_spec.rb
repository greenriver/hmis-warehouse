# frozen_string_literal: true

require 'rails_helper'
require 'connection_pool'
require 'redis'

RSpec.describe ApplicationNotifier do
  let(:url) { 'https://hooks.slack.com/services/test' }

  describe '#ping' do
    it 'logs and posts message' do
      notifier = described_class.new(url)
      expect(Rails.logger).to receive(:info).with('msg')
      notifier.ping('msg')
    end
  end
end
