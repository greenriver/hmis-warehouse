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
  # @param requests_to_send [Integer] how many requests to send before giving up
  # @param throttled_status [Integer] stop when we encounter this status
  # @param mode [Symbol] default
  def till_throttled(requests_to_send:, throttled_status: 429, mode: :default, &block)
    requests_sent = 0
    status_encountered = false

    case mode
    when :slow
      sleep_time = 0.2
      time_scale = 1.0
    when :default
      sleep_time = 0
      time_scale = 0.0001
    else
      raise 'unknown mode'
    end

    # travel to hour boundary so we always start at 00:00
    Timecop.travel((Time.current + 1.hour).beginning_of_hour)
    # adjust speed of time to reliably trigger burst throttling (10req/1sec)
    Timecop.scale(time_scale)
    begin
      (requests_to_send + 1).times do |cnt|
        block.arity == 1 ? yield(cnt) : yield
        sleep sleep_time
        requests_sent += 1
        status_encountered = response.status == throttled_status
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
      let(:path) { root_path }

      it 'throttle burst requests' do
        throttled_at = 10
        requests_sent = till_throttled(requests_to_send: throttled_at) { get(path) }
        expect(requests_sent).to eq(throttled_at)
      end
    end

    describe 'when hitting the history pdf' do
      let(:client) { create(:grda_warehouse_hud_client) }
      let(:path) { pdf_client_history_path(client) }

      it 'throttle burst requests' do
        throttled_at = 25
        requests_sent = till_throttled(requests_to_send: throttled_at, mode: :slow) { get(path) }
        expect(requests_sent).to eq(throttled_at)
      end
    end

    describe 'and posting to the sign-in page' do
      let(:path) { user_session_path }
      it 'throttles brute-force requests' do
        throttled_at = 20
        requests_sent = till_throttled(requests_to_send: throttled_at, mode: :slow) do |i|
          post(path, params: { user: { email: "test-#{i}@example.com", password: 'incorrect' } })
        end
        expect(requests_sent).to eq(throttled_at)
      end
    end

    describe 'HMIS sign-in end point' do
      let(:path) { hmis_user_session_path }
      it 'throttles brute-force requests' do
        throttled_at = 20
        requests_sent = till_throttled(requests_to_send: throttled_at, mode: :slow) do |i|
          post(path, params: { hmis_user: { email: "test-#{i}@example.com", password: 'password' } }, as: :json)
        end
        expect(requests_sent).to eq(throttled_at)
      end
    end

    describe 'Password Reset Throttling' do
      let(:path) { edit_user_password_path }
      it 'throttles brute-force password reset requests' do
        throttled_at = 20
        requests_sent = till_throttled(requests_to_send: throttled_at, mode: :slow) do |i|
          get(path, params: { reset_password_token: "FFFFFFFFFFFFFFFFFFF#{i}" })
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
      let(:path) { root_path }

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
        path = rollup_client_path(id: 1, partial: 'residential_enrollments')
        requests_sent = till_throttled(requests_to_send: throttled_at) { get(path) }
        expect(requests_sent).to eq(throttled_at)
      end
    end
  end

  context 'system_status_requests' do
    let(:path) { '/system_status/operational' }
    let(:headers) do
      { 'HTTP_USER_AGENT' => 'ELB-HealthChecker/2.0' }
    end

    it 'does not throttle requests' do
      throttled_at = 20
      requests_sent = till_throttled(requests_to_send: throttled_at) { get(path, headers: headers) }
      expect(requests_sent).to be_nil
    end
  end
end
