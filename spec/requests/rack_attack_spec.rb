###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# curl -I -s "http://hmis-url/?[1-350]" | grep HTTP/

RSpec.describe Rack::Attack, type: :request do
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
      time_advance = 1
    when :default
      time_advance = 0.01
    else
      raise 'unknown mode'
    end

    begin
      (requests_to_send + 1).times do |cnt|
        # travel to hour boundary so we always start at 00:00, manually advancing time every loop
        travel_to(Time.current.beginning_of_hour + (cnt * time_advance).seconds) unless time_advance.zero?
        block.arity == 1 ? yield(cnt) : yield
        requests_sent += 1
        status_encountered = response.status == throttled_status
        break if status_encountered
      end
    ensure
      travel_back
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
        requests_sent = till_throttled(requests_to_send: throttled_at) { get(path) }
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

    describe 'status endpoints' do
      let(:excluded_paths) { ['/messages/poll'] }
      let(:session_timeout) { Devise.timeout_in }

      it 'does not extend session lifetime for excluded paths' do
        excluded_paths.each do |path|
          # First request to establish session
          get path, xhr: true
          expect(response).to be_successful

          # Move time forward
          travel(session_timeout - 1.minutes)

          # Should still be logged in
          get path, xhr: true
          expect(response).to be_successful

          # Move time forward 2 more minutes (past the timeout)
          travel 2.minutes

          # Should be logged out
          get path, xhr: true
          expect(response).to have_http_status(:unauthorized)
        end
      end
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

  context 'sentry notification rate limiting' do
    let(:path) { '/' }

    it 'rate limits notifications to Sentry' do
      throttled_at = 20 # throttled at 10 currently
      allow(Sentry).to receive(:capture_message)

      # Send multiple requests in quick succession
      till_throttled(requests_to_send: throttled_at, throttled_status: -999) { get(path, headers: headers) }

      # Verify that Sentry was called only once for similar events
      expect(Sentry).to have_received(:capture_message).once
    end
  end
end
