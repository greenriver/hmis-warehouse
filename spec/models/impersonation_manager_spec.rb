###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ImpersonationManager do
  let(:session_id) { 'test-session-123' }
  let(:manager) { described_class.new(session_id) }
  let(:memory_store) { ActiveSupport::Cache.lookup_store(:memory_store) }

  before do
    allow(Rails).to receive(:cache).and_return(memory_store)
    Rails.cache.clear
  end

  describe '#initialize' do
    it 'sets session_id as string' do
      expect(manager.session_id).to eq('test-session-123')
    end

    it 'converts numeric session_id to string' do
      manager = described_class.new(12345)
      expect(manager.session_id).to eq('12345')
    end

    it 'converts nil session_id to empty string' do
      manager = described_class.new(nil)
      expect(manager.session_id).to eq('')
    end
  end

  describe '#store' do
    let(:true_user_id) { 1 }
    let(:impersonated_user_id) { 2 }

    it 'stores impersonation data in cache' do
      cache_key = manager.store(true_user_id, impersonated_user_id)
      expect(cache_key).to eq("impersonation:#{session_id}")

      stored_data = Rails.cache.read(cache_key)
      expect(stored_data[:true_user_id]).to eq(true_user_id)
      expect(stored_data[:impersonated_user_id]).to eq(impersonated_user_id)
      expect(stored_data[:session_id]).to eq(session_id)
    end

    it 'returns nil when session_id is blank' do
      manager = described_class.new('')
      result = manager.store(true_user_id, impersonated_user_id)
      expect(result).to be_nil
    end

    it 'returns nil when session_id is nil' do
      manager = described_class.new(nil)
      result = manager.store(true_user_id, impersonated_user_id)
      expect(result).to be_nil
    end
  end

  describe '#get' do
    let(:true_user_id) { 1 }
    let(:impersonated_user_id) { 2 }

    context 'when impersonation exists' do
      before do
        manager.store(true_user_id, impersonated_user_id)
      end

      it 'returns impersonation data hash' do
        data = manager.get
        expect(data).to be_a(Hash)
        expect(data[:true_user_id]).to eq(true_user_id)
        expect(data[:impersonated_user_id]).to eq(impersonated_user_id)
        expect(data[:session_id]).to eq(session_id)
      end

      it 'handles string keys from cache' do
        # Simulate cache returning string keys
        Rails.cache.write(
          manager.send(:cache_key), {
            'true_user_id' => true_user_id,
            'impersonated_user_id' => impersonated_user_id,
            'session_id' => session_id,
          }, expires_in: 24.hours
        )

        data = manager.get
        expect(data[:true_user_id]).to eq(true_user_id)
        expect(data[:impersonated_user_id]).to eq(impersonated_user_id)
        expect(data[:session_id]).to eq(session_id)
      end
    end

    context 'when session has changed' do
      before do
        manager.store(true_user_id, impersonated_user_id)
      end

      it 'returns nil when session_id does not match stored session_id' do
        # Simulate scenario where cache key is the same but session_id in data differs
        # This could happen if session was renewed but cache key somehow persisted
        old_cache_key = manager.send(:cache_key)
        Rails.cache.write(
          old_cache_key, {
            true_user_id: true_user_id,
            impersonated_user_id: impersonated_user_id,
            session_id: 'old-session-id', # Different from current session_id
          }, expires_in: 24.hours
        )

        # Now try to get with current manager (which has different session_id)
        data = manager.get
        expect(data).to be_nil
      end

      it 'returns nil when accessing with different session_id (different cache key)' do
        # Normal case: different session_id means different cache key, so no data found
        different_manager = described_class.new('different-session')
        data = different_manager.get
        expect(data).to be_nil
      end
    end

    context 'when impersonation does not exist' do
      it 'returns nil' do
        expect(manager.get).to be_nil
      end
    end

    context 'when session_id is blank' do
      let(:manager) { described_class.new('') }

      it 'returns nil' do
        expect(manager.get).to be_nil
      end
    end
  end

  describe '#clear' do
    let(:true_user_id) { 1 }
    let(:impersonated_user_id) { 2 }

    it 'removes impersonation data from cache' do
      manager.store(true_user_id, impersonated_user_id)
      expect(manager.get).to be_present

      manager.clear
      expect(manager.get).to be_nil
    end

    it 'does nothing when session_id is blank' do
      manager = described_class.new('')
      expect { manager.clear }.not_to raise_error
    end
  end

  describe '#active?' do
    let(:true_user_id) { 1 }
    let(:impersonated_user_id) { 2 }

    context 'when impersonation exists and session matches' do
      before do
        manager.store(true_user_id, impersonated_user_id)
      end

      it 'returns true' do
        expect(manager.active?).to be true
      end
    end

    context 'when impersonation does not exist' do
      it 'returns false' do
        expect(manager.active?).to be false
      end
    end

    context 'when session has changed' do
      before do
        manager.store(true_user_id, impersonated_user_id)
      end

      it 'returns false' do
        # Create a new manager with different session_id
        different_manager = described_class.new('different-session')
        expect(different_manager.active?).to be false
      end
    end
  end

  describe 'session isolation' do
    let(:session_1) { 'session-1' }
    let(:session_2) { 'session-2' }
    let(:manager_1) { described_class.new(session_1) }
    let(:manager_2) { described_class.new(session_2) }

    it 'prevents cross-session access' do
      manager_1.store(1, 2)
      expect(manager_1.get).to be_present
      expect(manager_2.get).to be_nil
    end
  end
end
