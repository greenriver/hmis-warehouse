require 'rails_helper'

# curl -I -s "http://hmis-url/?[1-350]" | grep HTTP/

describe Rack::Attack, type: :request do
  THROTTLED_AT = 11
  REQUEST_LIMIT = (THROTTLED_AT * 1.5).to_i

  # request a path repeatedly and return
  # the request number when it returns `throttled_status`
  def get_till_throttled(path, params: {}, headers: nil, requests_to_send: REQUEST_LIMIT, throttled_status: 429)
    # inject randomness to make sure we arent matching on params
    requests_sent = 0
    requests_to_send.times do |_|
      final_params = params.merge(randomness: SecureRandom.hex)
      get path, final_params, headers
      requests_sent += 1
      # puts "#{path} #{final_params} #{requests_sent}/#{requests_to_send} #{response.status}"
      break if response.status == throttled_status
    end
    requests_sent
  end

  before(:each) do
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
  end

  it 'does not throttle excessive test requests' do
    requests_sent = get_till_throttled('/', requests_to_send: REQUEST_LIMIT)
    expect(requests_sent).to be(REQUEST_LIMIT)
  end

  it 'throttle excessive requests by IP address - enabled' do
    requests_sent = get_till_throttled('/', params: { rack_attack_enabled: true }, requests_to_send: REQUEST_LIMIT)
    expect(requests_sent).to be(THROTTLED_AT)
  end
end
