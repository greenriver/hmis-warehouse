###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RedirectManager do
  let(:session_id) { 'test-session-123' }
  let(:manager) { described_class.new(session_id) }
  let(:redirect_url) { '/admin/users' }
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
    it 'stores redirect URL in cache' do
      cache_key = manager.store(redirect_url)
      expect(cache_key).to eq("redirect:#{session_id}")

      stored_url = Rails.cache.read(cache_key)
      expect(stored_url).to eq(redirect_url)
    end

    it 'returns cache key when successful' do
      cache_key = manager.store(redirect_url)
      expect(cache_key).to eq("redirect:#{session_id}")
    end

    it 'returns nil when session_id is blank' do
      manager = described_class.new('')
      result = manager.store(redirect_url)
      expect(result).to be_nil
    end

    it 'returns nil when url is blank' do
      result = manager.store('')
      expect(result).to be_nil
    end

    it 'returns nil when url is nil' do
      result = manager.store(nil)
      expect(result).to be_nil
    end

    it 'uses 1 hour TTL as safety measure' do
      expect(Rails.cache).to receive(:write).with(
        "redirect:#{session_id}",
        redirect_url,
        expires_in: 1.hour,
      )
      manager.store(redirect_url)
    end
  end

  describe '#get' do
    context 'when redirect URL exists' do
      before do
        manager.store(redirect_url)
      end

      it 'returns stored redirect URL' do
        expect(manager.get).to eq(redirect_url)
      end
    end

    context 'when redirect URL does not exist' do
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
    it 'removes redirect URL from cache' do
      manager.store(redirect_url)
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
    context 'when redirect URL exists' do
      before do
        manager.store(redirect_url)
      end

      it 'returns true' do
        expect(manager.active?).to be true
      end
    end

    context 'when redirect URL does not exist' do
      it 'returns false' do
        expect(manager.active?).to be false
      end
    end
  end

  describe 'session isolation' do
    let(:session_1) { 'session-1' }
    let(:session_2) { 'session-2' }
    let(:manager_1) { described_class.new(session_1) }
    let(:manager_2) { described_class.new(session_2) }

    it 'prevents cross-session access' do
      manager_1.store('/path1')
      expect(manager_1.get).to eq('/path1')
      expect(manager_2.get).to be_nil
    end
  end

  describe 'cache key format' do
    it 'uses correct cache key format' do
      manager.store(redirect_url)
      cache_key = manager.send(:cache_key)
      expect(cache_key).to eq("redirect:#{session_id}")
    end
  end
end
