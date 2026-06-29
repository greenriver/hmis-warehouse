###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Idp::ImpersonationManager do
  # A hash-backed stand-in for the Rails session. Crucially, session.id is nil — under JWT the
  # cookie-store session.id is unavailable during the request that first writes the session, so the
  # manager must NOT depend on it. It self-manages session[:impersonation_session_token] instead.
  def fake_session(initial = {})
    data = initial.dup
    instance_double('ActionDispatch::Request::Session').tap do |session|
      allow(session).to receive(:present?).and_return(true)
      allow(session).to receive(:id).and_return(nil)
      allow(session).to receive(:[]) { |key| data[key] }
      allow(session).to receive(:[]=) { |key, value| data[key] = value }
      allow(session).to receive(:delete) { |key| data.delete(key) }
      allow(session).to receive(:to_h).and_return(data)
    end
  end

  let(:true_user_id) { 1 }
  let(:impersonated_user_id) { 2 }

  describe '#initialize' do
    it 'stores session object when passed a session object' do
      session = fake_session
      manager = described_class.new(session)
      expect(manager.session).to eq(session)
    end

    it 'handles nil session' do
      manager = described_class.new(nil)
      expect(manager.session).to be_nil
    end
  end

  describe '#store' do
    it 'stores impersonation data stamped with a self-managed token and returns true' do
      session = fake_session
      manager = described_class.new(session)

      result = manager.store(true_user_id, impersonated_user_id)

      expect(result).to be true
      token = session[:impersonation_session_token]
      expect(token).to be_present
      expect(session[:impersonation]).to include(
        true_user_id: true_user_id,
        impersonated_user_id: impersonated_user_id,
        session_id: token,
      )
    end

    it 'reuses an existing token rather than minting a new one' do
      session = fake_session(impersonation_session_token: 'existing-token')
      manager = described_class.new(session)

      manager.store(true_user_id, impersonated_user_id)

      expect(session[:impersonation_session_token]).to eq('existing-token')
      expect(session[:impersonation][:session_id]).to eq('existing-token')
    end

    it 'returns false when there is no session' do
      manager = described_class.new(nil)
      expect(manager.store(true_user_id, impersonated_user_id)).to be false
    end
  end

  describe '#get' do
    it 'returns impersonation data hash with symbol keys when the token matches' do
      session = fake_session(
        impersonation_session_token: 'tok-1',
        impersonation: {
          true_user_id: true_user_id,
          impersonated_user_id: impersonated_user_id,
          session_id: 'tok-1',
        },
      )
      manager = described_class.new(session)

      data = manager.get
      expect(data).to be_a(Hash)
      expect(data[:true_user_id]).to eq(true_user_id)
      expect(data[:impersonated_user_id]).to eq(impersonated_user_id)
      expect(data[:session_id]).to eq('tok-1')
    end

    it 'handles string keys from session' do
      session = fake_session(
        impersonation_session_token: 'tok-1',
        impersonation: {
          'true_user_id' => true_user_id,
          'impersonated_user_id' => impersonated_user_id,
          'session_id' => 'tok-1',
        },
      )
      manager = described_class.new(session)

      data = manager.get
      expect(data[:true_user_id]).to eq(true_user_id)
      expect(data[:impersonated_user_id]).to eq(impersonated_user_id)
      expect(data[:session_id]).to eq('tok-1')
    end

    it 'returns nil when the stored token does not match the session token' do
      session = fake_session(
        impersonation_session_token: 'tok-1',
        impersonation: {
          true_user_id: true_user_id,
          impersonated_user_id: impersonated_user_id,
          session_id: 'a-different-token',
        },
      )
      manager = described_class.new(session)

      expect(manager.get).to be_nil
    end

    it 'returns nil when impersonation does not exist' do
      session = fake_session(impersonation_session_token: 'tok-1')
      manager = described_class.new(session)

      expect(manager.get).to be_nil
    end

    it 'returns nil when session is not present' do
      manager = described_class.new(nil)
      expect(manager.get).to be_nil
    end
  end

  describe 'store/get round-trip' do
    it 'honors impersonation written earlier in the same session (the JWT cross-request path)' do
      session = fake_session
      described_class.new(session).store(true_user_id, impersonated_user_id)

      # A fresh manager over the same session (mirrors the next request re-reading the cookie).
      data = described_class.new(session).get
      expect(data).to include(
        true_user_id: true_user_id,
        impersonated_user_id: impersonated_user_id,
      )
    end
  end

  describe '#clear' do
    it 'removes impersonation data from session' do
      session = fake_session(impersonation: { true_user_id: true_user_id })
      manager = described_class.new(session)

      manager.clear

      expect(session[:impersonation]).to be_nil
    end

    it 'does nothing when session is not present' do
      manager = described_class.new(nil)
      expect { manager.clear }.not_to raise_error
    end
  end
end
