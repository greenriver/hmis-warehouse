###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AuthMethod do
  before do
    allow(ENV).to receive(:fetch).and_call_original
  end

  describe '.jwt?' do
    it 'returns false when AUTH_METHOD is unset (defaults to devise)' do
      allow(ENV).to receive(:fetch).with('AUTH_METHOD', 'devise').and_return('devise')
      expect(described_class.jwt?).to be false
    end

    it 'returns true when AUTH_METHOD is jwt' do
      allow(ENV).to receive(:fetch).with('AUTH_METHOD', 'devise').and_return('jwt')
      expect(described_class.jwt?).to be true
    end
  end

  describe '.devise?' do
    it 'returns true when AUTH_METHOD is unset' do
      allow(ENV).to receive(:fetch).with('AUTH_METHOD', 'devise').and_return('devise')
      expect(described_class.devise?).to be true
    end

    it 'returns false when AUTH_METHOD is jwt' do
      allow(ENV).to receive(:fetch).with('AUTH_METHOD', 'devise').and_return('jwt')
      expect(described_class.devise?).to be false
    end
  end

  # The :devise group in Gemfile is required only on the Devise arm, which is what makes an
  # unintended reference to Devise or Warden raise here instead of resolving against a loaded gem.
  # A transitive require from any other gem restores them silently, so assert on the constants.
  describe 'the :devise bundler group', :jwt_only do
    it 'leaves Devise unloaded' do
      expect(defined?(Devise)).to be_nil
    end

    it 'leaves Warden unloaded' do
      expect(defined?(Warden)).to be_nil
    end
  end
end
