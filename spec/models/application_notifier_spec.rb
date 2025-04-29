# frozen_string_literal: true

require 'rails_helper'
require 'connection_pool'
require 'redis'

RSpec.describe ApplicationNotifier do
  let(:url) { 'https://hooks.slack.com/services/test' }
  let(:redis) do
    ConnectionPool.new {
      Redis.new(
        host: ENV['CACHE_HOST'],
        port: ENV['CACHE_PORT'],
        db: ENV['CACHE_DB']
      )
    }
  end

  before do
    allow(described_class).to receive(:redis).and_return(redis)
  end

  describe '#initialize' do
    it 'sets up redis and namespace' do
      notifier = described_class.new(url, channel: 'chan', username: 'user')
      expect(notifier.instance_variable_get(:@redis)).to eq(redis)
      expect(notifier.instance_variable_get(:@namespace)).to be_present
    end
  end

  describe '#ping' do
    it 'logs and posts message' do
      notifier = described_class.new(url)
      allow(notifier).to receive(:post)
      expect(Rails.logger).to receive(:info).with('msg')
      notifier.ping('msg')
    end
  end

  describe '#flush_queue' do
    it 'calls lpop and post for queued messages' do
      notifier = described_class.new(url)
      redis.with { |r| r.rpush("#{notifier.instance_variable_get(:@namespace)}/queue", 'test') }
      allow(notifier).to receive(:post)
      notifier.flush_queue
      expect(notifier).to have_received(:post)
    end
  end
end
