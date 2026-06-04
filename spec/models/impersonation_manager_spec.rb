###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ImpersonationManager do
  include_context 'with cache store'

  before do
    Rails.cache.clear
  end

  describe '#initialize' do
    it 'stores session object when passed a session object' do
      session = double(id: 'test-123')
      manager = described_class.new(session)
      expect(manager.session).to eq(session)
    end

    it 'handles string session_id (backwards compatibility)' do
      manager = described_class.new('test-session-id')
      expect(manager.session).to be_nil
    end

    it 'handles nil session' do
      manager = described_class.new(nil)
      expect(manager.session).to be_nil
    end
  end

  describe '#store' do
    let(:true_user_id) { 1 }
    let(:impersonated_user_id) { 2 }
    let(:session_id) { 'test-session-123' }

    context 'when using session storage (non-system test)' do
      before do
        allow(Rails.env).to receive(:test?).and_return(false)
      end

      it 'stores impersonation data in session and returns true' do
        session_data = {}
        session = double(id: session_id, present?: true, '[]': nil, '[]=': nil)
        allow(session).to receive(:[]=) do |key, value|
          session_data[key] = value
        end
        allow(session).to receive(:[]) { |key| session_data[key] }

        manager = described_class.new(session)
        result = manager.store(true_user_id, impersonated_user_id)

        expect(result).to be true
        expect(session_data[:impersonation]).to include(
          true_user_id: true_user_id,
          impersonated_user_id: impersonated_user_id,
          session_id: session_id,
        )
      end

      it 'returns false when session is not present' do
        manager = described_class.new(nil)
        result = manager.store(true_user_id, impersonated_user_id)
        expect(result).to be false
      end
    end

    context 'when using cache storage (system test)' do
      before do
        allow(Rails.env).to receive(:test?).and_return(true)
        allow(ENV).to receive(:[]).with('RUN_SYSTEM_TESTS').and_return('true')
      end

      it 'stores impersonation data in cache and returns true' do
        session = double(id: session_id)
        manager = described_class.new(session)

        result = manager.store(true_user_id, impersonated_user_id)

        expect(result).to be true
        cache_key = "impersonation:#{session_id}"
        stored_data = Rails.cache.read(cache_key)
        expect(stored_data[:true_user_id]).to eq(true_user_id)
        expect(stored_data[:impersonated_user_id]).to eq(impersonated_user_id)
        expect(stored_data[:session_id]).to eq(session_id)
      end
    end

    it 'returns false when session_id is blank' do
      manager = described_class.new('')
      result = manager.store(true_user_id, impersonated_user_id)
      expect(result).to be false
    end

    it 'returns false when session_id is nil' do
      manager = described_class.new(nil)
      result = manager.store(true_user_id, impersonated_user_id)
      expect(result).to be false
    end
  end

  describe '#get' do
    let(:true_user_id) { 1 }
    let(:impersonated_user_id) { 2 }
    let(:session_id) { 'test-session-123' }

    context 'when using session storage' do
      before do
        allow(Rails.env).to receive(:test?).and_return(false)
      end

      it 'returns impersonation data hash with symbol keys' do
        impersonation_data = {
          true_user_id: true_user_id,
          impersonated_user_id: impersonated_user_id,
          session_id: session_id,
        }
        session = double(id: session_id, present?: true, '[]': impersonation_data)

        manager = described_class.new(session)

        data = manager.get
        expect(data).to be_a(Hash)
        expect(data[:true_user_id]).to eq(true_user_id)
        expect(data[:impersonated_user_id]).to eq(impersonated_user_id)
        expect(data[:session_id]).to eq(session_id)
      end

      it 'handles string keys from session' do
        impersonation_data = {
          'true_user_id' => true_user_id,
          'impersonated_user_id' => impersonated_user_id,
          'session_id' => session_id,
        }
        session = double(id: session_id, present?: true)
        allow(session).to receive(:[]).with(:impersonation).and_return(impersonation_data)

        manager = described_class.new(session)

        data = manager.get
        expect(data[:true_user_id]).to eq(true_user_id)
        expect(data[:impersonated_user_id]).to eq(impersonated_user_id)
        expect(data[:session_id]).to eq(session_id)
      end

      it 'returns nil when session_id does not match stored session_id' do
        impersonation_data = {
          true_user_id: true_user_id,
          impersonated_user_id: impersonated_user_id,
          session_id: 'old-session-id',
        }
        session = double(id: session_id, present?: true)
        allow(session).to receive(:[]).with(:impersonation).and_return(impersonation_data)

        manager = described_class.new(session)

        data = manager.get
        expect(data).to be_nil
      end

      it 'returns nil when impersonation does not exist' do
        session = double(id: session_id, present?: true)
        allow(session).to receive(:[]).with(:impersonation).and_return(nil)

        manager = described_class.new(session)

        expect(manager.get).to be_nil
      end

      it 'returns nil when session is not present' do
        manager = described_class.new(nil)
        expect(manager.get).to be_nil
      end
    end

    context 'when using cache storage (system test)' do
      before do
        allow(Rails.env).to receive(:test?).and_return(true)
        allow(ENV).to receive(:[]).with('RUN_SYSTEM_TESTS').and_return('true')
      end

      it 'returns impersonation data from cache' do
        cache_key = "impersonation:#{session_id}"
        impersonation_data = {
          true_user_id: true_user_id,
          impersonated_user_id: impersonated_user_id,
          session_id: session_id,
        }
        Rails.cache.write(cache_key, impersonation_data, expires_in: 12.hours)

        session = double(id: session_id)
        manager = described_class.new(session)

        data = manager.get
        expect(data[:true_user_id]).to eq(true_user_id)
        expect(data[:impersonated_user_id]).to eq(impersonated_user_id)
        expect(data[:session_id]).to eq(session_id)
      end

      it 'returns nil when cache is empty' do
        session = double(id: session_id)
        manager = described_class.new(session)
        expect(manager.get).to be_nil
      end
    end
  end

  describe '#clear' do
    let(:true_user_id) { 1 }
    let(:impersonated_user_id) { 2 }
    let(:session_id) { 'test-session-123' }

    context 'when using session storage' do
      before do
        allow(Rails.env).to receive(:test?).and_return(false)
      end

      it 'removes impersonation data from session' do
        session_data = {}
        session = double(id: session_id, present?: true, delete: nil)
        allow(session).to receive(:delete) do |key|
          session_data.delete(key)
        end

        manager = described_class.new(session)
        manager.clear

        expect(session).to have_received(:delete).with(:impersonation)
      end

      it 'does nothing when session is not present' do
        manager = described_class.new(nil)
        expect { manager.clear }.not_to raise_error
      end
    end

    context 'when using cache storage (system test)' do
      before do
        allow(Rails.env).to receive(:test?).and_return(true)
        allow(ENV).to receive(:[]).with('RUN_SYSTEM_TESTS').and_return('true')
      end

      it 'removes impersonation data from cache' do
        cache_key = "impersonation:#{session_id}"
        impersonation_data = {
          true_user_id: true_user_id,
          impersonated_user_id: impersonated_user_id,
          session_id: session_id,
        }
        Rails.cache.write(cache_key, impersonation_data, expires_in: 12.hours)

        session = double(id: session_id)
        manager = described_class.new(session)
        manager.clear

        expect(Rails.cache.read(cache_key)).to be_nil
      end
    end
  end

  describe '#active?' do
    let(:true_user_id) { 1 }
    let(:impersonated_user_id) { 2 }
    let(:session_id) { 'test-session-123' }

    before do
      allow(Rails.env).to receive(:test?).and_return(false)
    end

    it 'returns true when impersonation exists and session matches' do
      impersonation_data = {
        true_user_id: true_user_id,
        impersonated_user_id: impersonated_user_id,
        session_id: session_id,
      }
      session = double(id: session_id, present?: true)
      allow(session).to receive(:[]).with(:impersonation).and_return(impersonation_data)

      manager = described_class.new(session)

      expect(manager.active?).to be true
    end

    it 'returns false when impersonation does not exist' do
      session = double(id: session_id, present?: true)
      allow(session).to receive(:[]).with(:impersonation).and_return(nil)

      manager = described_class.new(session)

      expect(manager.active?).to be false
    end

    it 'returns false when session_id does not match stored session_id' do
      impersonation_data = {
        true_user_id: true_user_id,
        impersonated_user_id: impersonated_user_id,
        session_id: 'different-session-id',
      }
      session = double(id: session_id, present?: true)
      allow(session).to receive(:[]).with(:impersonation).and_return(impersonation_data)

      manager = described_class.new(session)

      expect(manager.active?).to be false
    end
  end
end
