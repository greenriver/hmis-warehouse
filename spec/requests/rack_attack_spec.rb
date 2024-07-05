require 'rails_helper'

# curl -I -s "http://hmis-url/?[1-350]" | grep HTTP/

describe Rack::Attack, type: :request do
  let(:user) { create :user }

  # request a path repeatedly and return
  # the request number when it returns `throttled_status`
  def till_throttled(requests_to_send:, throttled_status: 429, &block)
    requests_sent = 0
    status_encountered = false
    requests_to_send.times do |cnt|
      block.arity == 0 ? yield : yield(cnt)
      requests_sent += 1
      status_encountered = response.status == throttled_status
      break if status_encountered
    end
    status_encountered ? requests_sent : nil
  end

  before(:each) do
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Timecop.scale(1 / 50.to_f)
  end

  describe 'when not-logged in' do
    describe 'when hitting the homepage' do
      let(:throttled_at) { 11 }
      let(:request_limit) { (throttled_at * 4).to_i }
      let(:path) { root_path(rack_attack_enabled: true) }

      it 'throttle excessive requests by IP address - enabled' do
        requests_sent = till_throttled(requests_to_send: request_limit) { get(path) }
        expect(requests_sent).to be_between(throttled_at, throttled_at + 1)
      end
    end

    describe 'and posting to the sign-in page' do
      let(:throttled_at) { 11 }
      let(:request_limit) { (throttled_at * 4).to_i }
      let(:path) { user_session_path(rack_attack_enabled: true) }

      it 'throttle excessive requests by user - enabled' do
        requests_sent = till_throttled(requests_to_send: request_limit) do
          post(path, params: {user: { email: "test@example.com", password: 'incorrect' }})
        end
        expect(requests_sent).to be_between(throttled_at, throttled_at + 1)
      end
    end

    describe 'and posting to the hmis sign-in end point' do
      let(:throttled_at) { 11 }
      let(:request_limit) { (throttled_at * 4).to_i }
      let(:path) { '/hmis/login' }

      it 'throttle excessive requests by user - enabled' do
        req_count = 0
        requests_sent = till_throttled(requests_to_send: request_limit) do
          post hmis_user_session_path(hmis_user: { email: user.email, password: user.password })
          payload = { user: { email: 'test@example.com', password: 'password' } }
          post hmis_user_session_path, params: payload.to_json, headers: { "CONTENT_TYPE" => "application/json" }
        end
        expect(requests_sent).to be_between(throttled_at, throttled_at + 1)
      end
    end
  end

  describe 'when logged in' do
    before do
      sign_in user
    end
    describe 'and hitting the homepage' do
      let(:throttled_at) { 151 }
      let(:request_limit) { (throttled_at * 4).to_i }
      let(:path) { '/' }

      it 'throttle excessive requests by IP address - enabled' do
        requests_sent = till_throttled(:get, path, params: { rack_attack_enabled: true }, requests_to_send: request_limit)
        expect(requests_sent).to be_between(throttled_at, throttled_at + 1)
      end
    end
    describe 'and hitting client rollups' do
      let(:throttled_at) { 251 }
      let(:request_limit) { (throttled_at * 4).to_i }
      let(:path) { '/clients/1/rollup/residential_enrollments' }

      it 'throttle excessive requests by IP address - enabled' do
        requests_sent = till_throttled(:get, path, params: { rack_attack_enabled: true }, requests_to_send: request_limit)
        expect(requests_sent).to be_between(throttled_at, throttled_at + 1)
      end
    end
  end
end
