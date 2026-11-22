###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::Place, type: :model do
  let(:initializer) { Rails.root.join('config/initializers/geocode_lite.rb') }
  let(:search_url) { Geocoder::Lookup.get(:nominatim).query_url(Geocoder::Query.new('1 Main St')) }
  let(:result) { instance_double(Geocoder::Result::Nominatim) }

  around do |example|
    original_env = ENV['NOMINATIM_HOST']
    had_nominatim_config = Geocoder.config.key?(:nominatim)
    original_config = Geocoder.config[:nominatim]
    example.run
  ensure
    ENV['NOMINATIM_HOST'] = original_env
    if had_nominatim_config
      Geocoder.config[:nominatim] = original_config
    else
      Geocoder.config.delete(:nominatim)
    end
    described_class.instance_variable_set(:@rate_limit, nil)
    described_class.instance_variable_set(:@places, nil)
    expect(Geocoder.config.key?(:nominatim)).to eq(had_nominatim_config)
    expect { search_url }.not_to raise_error
  end

  def reload_initializer(host)
    ENV['NOMINATIM_HOST'] = host
    Geocoder.config.delete(:nominatim)
    load initializer
  end

  describe 'geocoder configuration' do
    it 'targets the self-hosted server over http when NOMINATIM_HOST is set' do
      reload_initializer('http://nominatim.test:8080')

      expect(search_url).to start_with('http://nominatim.test:8080/search')
    end

    it 'targets the self-hosted server over https on the default port when NOMINATIM_HOST is an https URL' do
      reload_initializer('https://nominatim.test')

      expect(search_url).to start_with('https://nominatim.test:443/search')
    end

    it 'keeps a path prefix and drops a trailing slash from NOMINATIM_HOST' do
      reload_initializer('https://geo.test/nominatim/')

      expect(search_url).to start_with('https://geo.test:443/nominatim/search')
    end

    it 'raises at boot when NOMINATIM_HOST has no scheme' do
      expect { reload_initializer('nominatim.test:8080') }.to raise_error(ArgumentError, /NOMINATIM_HOST must be an http/)
    end

    it 'targets the public API over https when NOMINATIM_HOST is unset' do
      reload_initializer(nil)

      expect(search_url).to start_with('https://nominatim.openstreetmap.org/search')
    end

    it 'treats a blank NOMINATIM_HOST as unset' do
      reload_initializer('')

      expect(search_url).to start_with('https://nominatim.openstreetmap.org/search')
    end

    it 'allows the self-hosted server 30 seconds per request' do
      reload_initializer('http://nominatim.test:8080')

      expect(Geocoder.config_for_lookup(:nominatim).timeout).to eq(30)
    end

    it 'keeps the 10 second request timeout for the public API' do
      reload_initializer(nil)

      expect(Geocoder.config_for_lookup(:nominatim).timeout).to eq(10)
    end
  end

  describe '.self_hosted_nominatim?' do
    it 'is true when NOMINATIM_HOST is set' do
      ENV['NOMINATIM_HOST'] = 'http://nominatim.test:8080'

      expect(described_class.self_hosted_nominatim?).to be(true)
    end

    it 'is false when NOMINATIM_HOST is unset' do
      ENV['NOMINATIM_HOST'] = nil

      expect(described_class.self_hosted_nominatim?).to be(false)
    end
  end

  describe '.nominatim_lookup' do
    before do
      allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
      allow(Geocoder).to receive(:search).and_return([result])
      allow(described_class).to receive(:sleep)
    end

    def lookup
      described_class.nominatim_lookup('1 Main St', 'Boston', 'MA', '02101', 'US')
    end

    it 'does not sleep between consecutive calls when self-hosted' do
      ENV['NOMINATIM_HOST'] = 'http://nominatim.test:8080'

      expect(lookup).to eq(result)
      expect(lookup).to eq(result)

      expect(described_class).not_to have_received(:sleep)
    end

    it 'sleeps once before the second consecutive call against the public API' do
      ENV['NOMINATIM_HOST'] = nil

      expect(lookup).to eq(result)
      expect(lookup).to eq(result)

      expect(described_class).to have_received(:sleep).with(1).once
    end

    context 'when the self-hosted server cannot be reached' do
      before do
        reload_initializer('http://nominatim.test:8080')
        allow(Geocoder).to receive(:search).and_call_original
      end

      {
        'refuses the connection' => ->(stub) { stub.to_raise(Errno::ECONNREFUSED) },
        'times out' => lambda(&:to_timeout),
        'does not resolve' => ->(stub) { stub.to_raise(SocketError) },
        'resets the connection' => ->(stub) { stub.to_raise(Errno::ECONNRESET) },
      }.each do |failure, configure_stub|
        it "returns nil and pauses lookups for an hour when the server #{failure}" do
          request = configure_stub.call(stub_request(:get, 'http://nominatim.test:8080/search').with(query: hash_including({})))

          expect(lookup).to be_nil

          expect(request).to have_been_requested.once
          expect(Rails.cache.read(['Nominatim', 'API PAUSE'])).to be(true)
        end
      end
    end

    it 'returns nil without pausing lookups when the public API refuses the connection' do
      reload_initializer(nil)
      allow(Geocoder).to receive(:search).and_call_original
      request = stub_request(:get, 'https://nominatim.openstreetmap.org/search').with(query: hash_including({})).to_raise(Errno::ECONNREFUSED)

      expect(lookup).to be_nil

      expect(request).to have_been_requested.once
      expect(Rails.cache.read(['Nominatim', 'API PAUSE'])).to be_nil
    end

    it 'skips the search while the API is paused' do
      Rails.cache.write(['Nominatim', 'API PAUSE'], true, expires_in: 1.hour)

      expect(lookup).to be_nil

      expect(Geocoder).not_to have_received(:search)
    end
  end

  describe '.lookup' do
    before do
      allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
      allow(Sentry).to receive(:capture_exception)
      allow(described_class).to receive(:send_single_notification)
      reload_initializer('http://nominatim.test:8080')
      stub_request(:get, 'http://nominatim.test:8080/search').with(query: hash_including({})).to_raise(Errno::ECONNREFUSED)
    end

    it 'returns nil, pauses lookups and reports no error when the self-hosted server refuses the connection' do
      expect(described_class.lookup(query: '1 Main St', city: 'Boston', state: 'MA', postalcode: '02101')).to be_nil

      expect(Rails.cache.read(['Nominatim', 'API PAUSE'])).to be(true)
      expect(Sentry).not_to have_received(:capture_exception)
      expect(described_class).not_to have_received(:send_single_notification)
    end
  end
end
