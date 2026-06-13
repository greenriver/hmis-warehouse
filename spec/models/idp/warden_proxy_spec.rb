###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Idp::WardenProxy do
  let(:user) { double('User', id: 1) }
  let(:other_user) { double('User', id: 2) }
  let(:session) { { foo: 'bar' } }

  describe '#user' do
    it 'returns the user for scope :user' do
      proxy = described_class.new(user)
      expect(proxy.user(scope: :user)).to eq(user)
    end

    it 'defaults to scope :user' do
      proxy = described_class.new(user)
      expect(proxy.user).to eq(user)
    end

    it 'returns nil for scope :hmis_user' do
      proxy = described_class.new(user)
      expect(proxy.user(scope: :hmis_user)).to be_nil
    end

    it 'returns nil when no user is present' do
      proxy = described_class.new(nil)
      expect(proxy.user).to be_nil
    end
  end

  describe '#authenticated?' do
    it 'returns true when a user is present for scope :user' do
      proxy = described_class.new(user)
      expect(proxy.authenticated?(scope: :user)).to be true
    end

    it 'returns false when no user is present' do
      proxy = described_class.new(nil)
      expect(proxy.authenticated?(scope: :user)).to be false
    end

    it 'returns false for a non-user scope even when a user is present' do
      proxy = described_class.new(user)
      expect(proxy.authenticated?(scope: :hmis_user)).to be false
    end
  end

  describe '#authenticate?' do
    it 'tracks presence like authenticated?' do
      expect(described_class.new(user).authenticate?(scope: :user)).to be true
      expect(described_class.new(nil).authenticate?(scope: :user)).to be false
    end
  end

  describe '#authenticate!' do
    it 'returns the current user without performing authentication' do
      proxy = described_class.new(user)
      expect(proxy.authenticate!).to eq(user)
    end
  end

  describe '#set_user' do
    it 'sets the user for scope :user' do
      proxy = described_class.new(nil)
      proxy.set_user(user, scope: :user)
      expect(proxy.user).to eq(user)
    end

    it 'does not set the user for a non-user scope' do
      proxy = described_class.new(user)
      proxy.set_user(other_user, scope: :hmis_user)
      expect(proxy.user).to eq(user)
    end
  end

  describe '#session' do
    it 'returns the session passed at construction' do
      proxy = described_class.new(user, session: session)
      expect(proxy.session).to eq(session)
    end

    it 'returns nil when no session was provided' do
      proxy = described_class.new(user)
      expect(proxy.session).to be_nil
    end
  end
end
