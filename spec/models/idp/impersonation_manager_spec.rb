###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Idp::ImpersonationManager do
  describe '#initialize' do
    it 'stores session object when passed a session object' do
      session = double(id: 'test-123')
      manager = described_class.new(session)
      expect(manager.session).to eq(session)
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

  describe '#clear' do
    let(:true_user_id) { 1 }
    let(:impersonated_user_id) { 2 }
    let(:session_id) { 'test-session-123' }

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
end
