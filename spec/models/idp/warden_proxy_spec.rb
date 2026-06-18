###
# Copyright Green River Data Group, Inc.
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

    # Warden/Devise call positionally (e.g. user(:user)) far more than via scope:.
    it 'returns the user for a positional :user scope' do
      proxy = described_class.new(user)
      expect(proxy.user(:user)).to eq(user)
    end

    it 'returns nil for a positional :hmis_user scope' do
      proxy = described_class.new(user)
      expect(proxy.user(:hmis_user)).to be_nil
    end

    # Devise splats strategies followed by an options hash: user(:strategy, scope: :user).
    # This guards that a leading positional strategy is not mistaken for the scope.
    it 'returns the user for a splatted strategies + scope: :user hash' do
      proxy = described_class.new(user)
      expect(proxy.user(:password, :token, scope: :user)).to eq(user)
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

    # Devise's helpers pass a block that must run only on successful authentication.
    it 'yields when authenticated' do
      proxy = described_class.new(user)
      expect { |b| proxy.authenticated?(scope: :user, &b) }.to yield_control
    end

    it 'does not yield when not authenticated' do
      proxy = described_class.new(nil)
      expect { |b| proxy.authenticated?(scope: :user, &b) }.not_to yield_control
    end

    it 'does not yield for a non-user scope even when a user is present' do
      proxy = described_class.new(user)
      expect { |b| proxy.authenticated?(scope: :hmis_user, &b) }.not_to yield_control
    end
  end

  describe '#authenticate?' do
    it 'tracks presence like authenticated?' do
      expect(described_class.new(user).authenticate?(scope: :user)).to be true
      expect(described_class.new(nil).authenticate?(scope: :user)).to be false
    end

    it 'yields when authentication succeeds' do
      proxy = described_class.new(user)
      expect { |b| proxy.authenticate?(scope: :user, &b) }.to yield_control
    end

    it 'does not yield when authentication fails' do
      proxy = described_class.new(nil)
      expect { |b| proxy.authenticate?(scope: :user, &b) }.not_to yield_control
    end
  end

  describe '#authenticate!' do
    it 'returns the current user without performing authentication' do
      proxy = described_class.new(user)
      expect(proxy.authenticate!).to eq(user)
    end

    # Devise calls authenticate! with splatted strategies and a trailing scope: hash.
    it 'returns the user for a splatted strategies + scope: :user hash' do
      proxy = described_class.new(user)
      expect(proxy.authenticate!(:password, scope: :user)).to eq(user)
    end

    # authenticate! is the "require a user or halt" gate; under JWT a non-:user scope never
    # carries a user, so it must fail loudly rather than hand back nil and let the caller treat
    # "no exception" as success.
    it 'raises for a non-:user scope' do
      proxy = described_class.new(user)
      expect { proxy.authenticate!(:password, scope: :hmis_user) }.to raise_error(Warden::NotAuthenticated)
    end

    it 'raises when there is no authenticated user for the :user scope' do
      proxy = described_class.new(nil)
      expect { proxy.authenticate! }.to raise_error(Warden::NotAuthenticated)
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

  describe '#logout' do
    it 'clears the user when no scope is given' do
      proxy = described_class.new(user)
      proxy.logout
      expect(proxy.user).to be_nil
    end

    it 'clears the user when the :user scope is targeted' do
      proxy = described_class.new(user)
      proxy.logout(:user)
      expect(proxy.user).to be_nil
    end

    it 'leaves the user intact when only a non-:user scope is targeted' do
      proxy = described_class.new(user)
      proxy.logout(:hmis_user)
      expect(proxy.user).to eq(user)
    end

    it 'clears the user when :user is among several targeted scopes' do
      proxy = described_class.new(user)
      proxy.logout(:hmis_user, :user)
      expect(proxy.user).to be_nil
    end
  end

  # These exist solely so Devise's sign_in / sign_out / failure paths don't blow up.
  # A rename or removal would raise NoMethodError in production auth flows.
  describe 'Devise compatibility surface' do
    let(:proxy) { described_class.new(user) }

    it 'returns nil from #winning_strategy' do
      expect(proxy.winning_strategy).to be_nil
    end

    it 'returns nil from #message' do
      expect(proxy.message).to be_nil
    end

    it 'responds to #lock! without raising' do
      expect { proxy.lock! }.not_to raise_error
    end

    it 'responds to #clear_strategies_cache! without raising' do
      expect { proxy.clear_strategies_cache! }.not_to raise_error
    end
  end
end
