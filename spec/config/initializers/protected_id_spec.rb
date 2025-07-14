###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProtectedId::Encoder do
  describe '#sanitize_value' do
    it 'removes null bytes from strings' do
      value_with_null = "test\x00string"
      sanitized = described_class.send(:sanitize_value, value_with_null)
      expect(sanitized).to eq('teststring')
    end

    it 'removes other control characters from strings' do
      value_with_controls = "test\x01\x02\x03string"
      sanitized = described_class.send(:sanitize_value, value_with_controls)
      expect(sanitized).to eq('teststring')
    end

    it 'strips whitespace from strings' do
      value_with_whitespace = '  test string  '
      sanitized = described_class.send(:sanitize_value, value_with_whitespace)
      expect(sanitized).to eq('test string')
    end

    it 'returns non-string values unchanged' do
      expect(described_class.send(:sanitize_value, 123)).to eq(123)
      expect(described_class.send(:sanitize_value, nil)).to eq(nil)
      expect(described_class.send(:sanitize_value, [1, 2, 3])).to eq([1, 2, 3])
    end

    it 'handles empty strings' do
      expect(described_class.send(:sanitize_value, '')).to eq('')
      expect(described_class.send(:sanitize_value, '   ')).to eq('')
    end
  end
end
