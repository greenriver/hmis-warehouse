###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# Tests for CACHE_AUTH_TOKEN conditional logic. No real Redis connection is made.
# Mirrors the logic in: config/cable.yml, config/environments/*.rb, config/initializers/session_store.rb
#
# Full end-to-end verification (that Rails.cache, Action Cable, and sessions actually
# connect to Valkey using the built config) must be confirmed manually in dev/staging.
RSpec.describe 'CACHE_AUTH_TOKEN config (cache, session, cable)' do
  def with_env(key, value)
    original = ENV[key]
    if value.nil?
      ENV.delete(key)
    else
      ENV[key] = value
    end
    yield
  ensure
    if original.nil?
      ENV.delete(key)
    else
      ENV[key] = original
    end
  end

  # Same merge pattern as development.rb, staging.rb, production.rb
  def redis_config_with_auth(base = { host: 'redis', port: 6379, db: 1 })
    base.merge(ENV['CACHE_AUTH_TOKEN'].present? ? { password: ENV['CACHE_AUTH_TOKEN'] } : {})
  end

  # Same URL logic as config/cable.yml
  def cable_url(scheme:, cache_host: 'redis', cache_port: '6379', cache_db: '1')
    auth = ENV['CACHE_AUTH_TOKEN'].present? ? ":#{ENV['CACHE_AUTH_TOKEN']}@" : ''
    "#{scheme}#{auth}#{cache_host}:#{cache_port}/#{cache_db}"
  end

  describe 'redis_config merge (cache_store, session_store)' do
    it 'omits password when CACHE_AUTH_TOKEN is unset' do
      with_env('CACHE_AUTH_TOKEN', nil) do
        config = redis_config_with_auth
        expect(config).to eq(host: 'redis', port: 6379, db: 1)
        expect(config).not_to have_key(:password)
      end
    end

    it 'omits password when CACHE_AUTH_TOKEN is blank' do
      with_env('CACHE_AUTH_TOKEN', '') do
        config = redis_config_with_auth
        expect(config).not_to have_key(:password)
      end
    end

    it 'includes password when CACHE_AUTH_TOKEN is set' do
      with_env('CACHE_AUTH_TOKEN', 'devtoken') do
        config = redis_config_with_auth
        expect(config[:password]).to eq('devtoken')
      end
    end
  end

  describe 'cable URL format' do
    it 'omits auth segment when CACHE_AUTH_TOKEN is blank' do
      with_env('CACHE_AUTH_TOKEN', nil) do
        expect(cable_url(scheme: 'redis://')).to eq('redis://redis:6379/1')
      end
    end

    it 'includes :token@ when CACHE_AUTH_TOKEN is set' do
      with_env('CACHE_AUTH_TOKEN', 'devtoken') do
        expect(cable_url(scheme: 'redis://')).to eq('redis://:devtoken@redis:6379/1')
      end
    end
  end
end
