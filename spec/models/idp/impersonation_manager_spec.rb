###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Idp::ImpersonationManager do
  # A hash-backed stand-in for the Rails session. present? is derived from the backing hash (NOT
  # hard-coded true): a fresh, unwritten ActionDispatch session is blank? → present? == false. The
  # manager must gate store on nil rather than present?, because the impersonation write is
  # frequently the FIRST write to the session. Deriving present? from `data` is what lets these
  # tests catch a regression that reintroduces a present? gate.
  def fake_session(initial = {})
    data = initial.dup
    instance_double('ActionDispatch::Request::Session').tap do |session|
      allow(session).to receive(:present?) { data.present? }
      allow(session).to receive(:[]) { |key| data[key] }
      allow(session).to receive(:[]=) { |key, value| data[key] = value }
      allow(session).to receive(:delete) { |key| data.delete(key) }
    end
  end

  let(:true_user_id) { 1 }
  let(:impersonated_user_id) { 2 }

  describe '#store' do
    it 'writes to a blank session and returns true (the first-write case a present? gate would refuse)' do
      session = fake_session
      expect(session).not_to be_present # guard: we are really exercising the blank-session path

      result = described_class.new(session).store(true_user_id, impersonated_user_id)

      expect(result).to be true
      expect(session[:impersonation]).to eq(
        true_user_id: true_user_id,
        impersonated_user_id: impersonated_user_id,
      )
    end

    it 'returns false when there is no session' do
      manager = described_class.new(nil)
      expect(manager.store(true_user_id, impersonated_user_id)).to be false
    end
  end

  describe '#get' do
    it 'normalizes string keys from the cookie store to symbols' do
      session = fake_session(
        impersonation: {
          'true_user_id' => true_user_id,
          'impersonated_user_id' => impersonated_user_id,
        },
      )

      expect(described_class.new(session).get).to eq(
        true_user_id: true_user_id,
        impersonated_user_id: impersonated_user_id,
      )
    end

    it 'returns nil when no impersonation is stored' do
      expect(described_class.new(fake_session).get).to be_nil
    end

    it 'returns nil when session is nil' do
      expect(described_class.new(nil).get).to be_nil
    end
  end

  describe 'store/get round-trip (the JWT cross-request path)' do
    it 'reads back impersonation written on an earlier request, tolerating cookie key-stringification' do
      session = fake_session
      described_class.new(session).store(true_user_id, impersonated_user_id)

      # A real next request re-reads the cookie: the JSON cookie serializer returns nested keys as
      # strings. Simulate that so the round-trip actually exercises get's normalization.
      session[:impersonation] = session[:impersonation].deep_stringify_keys

      data = described_class.new(session).get
      expect(data).to eq(
        true_user_id: true_user_id,
        impersonated_user_id: impersonated_user_id,
      )
    end
  end

  describe '#clear' do
    it 'removes impersonation data from the session' do
      session = fake_session(impersonation: { true_user_id: true_user_id })

      described_class.new(session).clear

      expect(session[:impersonation]).to be_nil
    end

    it 'does nothing when session is nil' do
      manager = described_class.new(nil)
      expect { manager.clear }.not_to raise_error
    end
  end
end
