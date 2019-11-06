require 'rails_helper'

# curl -I -s "http://hmis-url/?[1-350]" | grep HTTP/

describe Rack::Attack, type: :request do
  let(:user) { create :user }

  # request a path repeatedly and return
  # the request number when it returns `throttled_status`
  def till_throttled(method, path, options = {})
    requests_to_send = options.delete(:requests_to_send)
    throttled_status = options.delete(:throttled_status) || 429
    options[:params] ||= {}
    # inject randomness to make sure we arent matching on params
    requests_sent = 0
    requests_to_send.times do |_|
      options[:params][:randomness] = SecureRandom.hex
      send(method, path, options[:params])
      requests_sent += 1
      # puts "#{path} #{options} #{requests_sent}/#{requests_to_send} #{response.status}"
      break if response.status == throttled_status
    end
    requests_sent
  end

  before do
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Timecop.scale(1 / 100.to_f)
  end

  describe 'when not-logged in' do
    describe 'when hitting the homepage' do
      let(:throttled_at) { 6 }
      let(:request_limit) { (throttled_at * 4).to_i }
      let(:path) { '/' }
      it 'does not throttle excessive test requests' do
        requests_sent = till_throttled(:get, path, requests_to_send: request_limit)
        expect(requests_sent).to be(request_limit)
      end

      it 'throttle excessive requests by IP address - enabled' do
        requests_sent = till_throttled(
          :get,
          path,
          requests_to_send: request_limit,
          params: { rack_attack_enabled: true },
        )
        expect(requests_sent).to be(throttled_at)
      end
    end

    describe 'and posting to the sign-in page' do
      let(:throttled_at) { 11 }
      let(:request_limit) { (throttled_at * 4).to_i }
      let(:path) { '/users/sign_in' }

      it 'does not throttle excessive test requests' do
        requests_sent = till_throttled(
          :post,
          path,
          requests_to_send: request_limit,
          params: {
            user: { email: 'test@example.com', password: 'password' },
          },
        )
        expect(requests_sent).to be(request_limit)
      end

      it 'throttle excessive requests by user - enabled' do
        requests_sent = till_throttled(
          :post,
          path,
          requests_to_send: request_limit,
          params: {
            rack_attack_enabled: true,
            user: { email: 'test@example.com', password: 'password' },
          },
        )
        expect(requests_sent).to be(throttled_at)
      end
    end
  end

  describe 'when logged in' do
    before do
      sign_in user
    end
    describe 'and hitting the homepage' do
      let(:throttled_at) { 51 }
      let(:request_limit) { (throttled_at * 4).to_i }
      let(:path) { '/' }

      it 'does not throttle excessive test requests' do
        requests_sent = till_throttled(:get, path, requests_to_send: request_limit)
        expect(requests_sent).to be(request_limit)
      end

      it 'throttle excessive requests by IP address - enabled' do
        requests_sent = till_throttled(:get, path, params: { rack_attack_enabled: true }, requests_to_send: request_limit)
        expect(requests_sent).to be(throttled_at)
      end
    end
    describe 'and hitting client rollups' do
      let(:throttled_at) { 101 }
      let(:request_limit) { (throttled_at * 4).to_i }
      let(:path) { '/clients/1/rollup/residential_enrollments' }

      it 'does not throttle excessive test requests' do
        requests_sent = till_throttled(:get, path, requests_to_send: request_limit)
        expect(requests_sent).to be(request_limit)
      end

      it 'throttle excessive requests by IP address - enabled' do
        requests_sent = till_throttled(:get, path, params: { rack_attack_enabled: true }, requests_to_send: request_limit)
        expect(requests_sent).to be(throttled_at)
      end
    end
  end
end
