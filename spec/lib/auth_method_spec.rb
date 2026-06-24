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
end
