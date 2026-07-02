###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisSimulation::Hashing do
  describe '.stable_hash' do
    it 'returns the same value for the same input across multiple calls' do
      value = described_class.stable_hash('test-context')
      expect(described_class.stable_hash('test-context')).to eq(value)
    end

    it 'returns different values for different inputs' do
      expect(described_class.stable_hash('foo')).not_to eq(described_class.stable_hash('bar'))
    end

    it 'returns a non-negative integer within the SHA-256-derived range' do
      value = described_class.stable_hash('test')
      expect(value).to be_a(Integer)
      expect(value).to be_between(0, 2**62)
    end

    it 'handles numeric-looking strings differently from each other' do
      expect(described_class.stable_hash('cls_jitter:FAKE123:1')).not_to(
        eq(described_class.stable_hash('cls_jitter:FAKE123:2')),
      )
    end

    it 'coerces non-string input to string without raising' do
      expect { described_class.stable_hash(:symbol_key) }.not_to raise_error
      expect { described_class.stable_hash(nil) }.not_to raise_error
    end
  end
end
