require 'rails_helper'

# curl -I -s "http://hmis-url/?[1-350]" | grep HTTP/

describe Rack::Attack, type: :request do
  let(:user) { create :user }

  before(:all) do
    Rack::Attack.enabled = true
  end

  after(:all) do
    Rack::Attack.enabled = false
  end

  # request a path repeatedly and return
  # the request number when it returns `throttled_status`
  def till_throttled(requests_to_send:, throttled_status: 429, time_scale: 0.001, &block)
    requests_sent = 0
    status_encountered = false

    # adjust speed of time to reliably trigger throttling
    Timecop.scale(time_scale.to_f)
    begin
      (requests_to_send + 1).times do |cnt|
        block.arity == 1 ? yield(cnt) : yield
        requests_sent += 1
        status_encountered = response.status == throttled_status
        puts [cnt, response.status].inspect
        break if status_encountered
      end
    ensure
      Timecop.return
    end
    status_encountered ? requests_sent - 1 : nil
  end

  before(:each) do
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
  end

  describe 'when not-logged in' do
    describe 'when hitting the homepage' do
      let(:path) { root_path() }

      it 'throttle burst requests' do
        throttled_at = 10
        requests_sent = till_throttled(requests_to_send: throttled_at) { get(path) }
        expect(requests_sent).to eq(throttled_at)
      end
    end

    describe 'and posting to the sign-in page' do
      let(:path) { user_session_path() }
      it 'throttles brute-force requests' do
        throttled_at = 20
        requests_sent = till_throttled(requests_to_send: throttled_at, time_scale: 1.0) do |i|
          post(path, params: { user: { email: "test-#{i}@example.com", password: 'incorrect' } })
          sleep 0.1
        end
        expect(requests_sent).to eq(throttled_at)
      end
    end

    describe 'HMIS sign-in end point' do
      let(:path) { hmis_user_session_path() }

      it 'throttles brute-force requests' do
        throttled_at = 10
        requests_sent = till_throttled(requests_to_send: throttled_at) do |i|
          post(path, params: { hmis_user: { email: "test-#{i}@example.com", password: 'password' } }, as: :json)
        end
        expect(requests_sent).to eq(throttled_at)
      end
    end

    describe 'Password Reset Throttling' do
      let(:path) { user_password_path() }
      it 'throttles brute-force password reset requests' do
        throttled_at = 20
        requests_sent = till_throttled(requests_to_send: throttled_at, time_scale: 1.0) do |i|
          get(path, params: {reset_password_token: 'Y57vKKE0g0J9z84nuAcs'})
          sleep 0.1
        end
        expect(requests_sent).to eq(throttled_at)
      end
    end
  end

  describe 'when logged in' do
    before do
      sign_in user
    end

    describe 'and hitting the homepage' do
      let(:path) { root_path() }

      it 'throttle excessive requests by IP address - enabled' do
        throttled_at = 150
        requests_sent = till_throttled(requests_to_send: throttled_at) { get(path) }
        expect(requests_sent).to eq(throttled_at)
      end
    end

    describe 'and hitting client rollups' do
      let(:throttled_at) { 250 }

      it 'throttle excessive requests by IP address - enabled' do
        throttled_at = 250
        # /clients/1/rollup/residential_enrollments
        path = rollup_client_path(id: 1, partial: 'residential_enrollments', )
        requests_sent = till_throttled(requests_to_send: throttled_at) { get(path) }
        expect(requests_sent).to eq(throttled_at)
      end
    end
  end
end
