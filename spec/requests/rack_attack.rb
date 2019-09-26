require 'rails_helper'

# curl -I -s "http://hmis-url/?[1-350]" | grep HTTP/

describe Rack::Attack, type: :request do
  before(:each) do
    setup_rack_attack_cache_store
    avoid_test_overlaps_in_cache
  end

  def setup_rack_attack_cache_store
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
  end

  def avoid_test_overlaps_in_cache
    Rails.cache.clear
  end

  it 'throttle excessive requests by IP address' do
    limit = 300
    period = 300
    ip = '1.2.3.4'
    limit.times do
      Rack::Attack.cache.count("requests/ip:#{ip}", period)
    end

    get '/', headers: { REMOTE_ADDR: ip }

    expect(response).to have_http_status(:too_many_requests)
  end
end
