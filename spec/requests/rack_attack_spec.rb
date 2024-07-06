require 'rails_helper'

# curl -I -s "http://hmis-url/?[1-350]" | grep HTTP/

describe Rack::Attack, type: :request do
  let(:user) { create :user }

  # request a path repeatedly and return
  # the request number when it returns `throttled_status`
  def till_throttled(requests_to_send:, throttled_status: 429, &block)
    requests_sent = 0
    status_encountered = false
    (requests_to_send + 1).times do |cnt|
      block.arity == 0 ? yield : yield(cnt)
      requests_sent += 1
      status_encountered = response.status == throttled_status
      break if status_encountered
    end
    status_encountered ? requests_sent - 1: nil
  end

  before(:each) do
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    # Slow down time to more reliably trigger throttling
    Timecop.scale(0.001)
  end

  describe 'when not-logged in' do
    describe 'when hitting the homepage' do
      let(:throttled_at) { 10 }
      let(:path) { root_path(rack_attack_enabled: true) }

      it 'throttle excessive requests by IP address - enabled' do
        requests_sent = till_throttled(requests_to_send: throttled_at) { get(path) }
        expect(requests_sent).to eq(throttled_at)
      end
    end

    describe 'and posting to the sign-in page' do
      let(:throttled_at) { 10 }
      let(:path) { user_session_path(rack_attack_enabled: true) }

      it 'throttles excessive requests by submitted email' do
        requests_sent = till_throttled(requests_to_send: throttled_at) do
          post(path, params: {user: { email: "test@example.com", password: 'incorrect' }})
        end
        expect(requests_sent).to eq(throttled_at)
      end
    end

    describe 'and posting to the hmis sign-in end point' do
      let(:throttled_at) { 10 }
      let(:path) { hmis_user_session_path(rack_attack_enabled: true) }

      it 'throttles excessive requests by submitted email' do
        requests_sent = till_throttled(requests_to_send: throttled_at) do
          post(path, params:{ hmis_user: { email: 'test@example.com', password: 'password' } }, as: :json)
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
      let(:throttled_at) { 150 }
      let(:path) { root_path(rack_attack_enabled: true) }

      it 'throttle excessive requests by IP address - enabled' do
        requests_sent = till_throttled(requests_to_send: throttled_at) { get(path) }
        expect(requests_sent).to eq(throttled_at)
      end
    end

    describe 'and hitting client rollups' do
      let(:throttled_at) { 250 }
      # /clients/1/rollup/residential_enrollments
      let(:path) { rollup_client_path(id: 1, partial: 'residential_enrollments', rack_attack_enabled: true) }

      it 'throttle excessive requests by IP address - enabled' do
        requests_sent = till_throttled(requests_to_send: throttled_at) {get(path) }
        expect(requests_sent).to eq(throttled_at)
      end
    end
  end
end
