# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ActivityLog, type: :model do
  describe '.scrub' do
    it 'calls method that contains gsub! operations for path cleaning' do
      # Test the gsub! operations from lines 47, 48: row[:path]&.gsub!(/\?.*/, ''), row[:referrer]&.gsub!(/\?.*/, '')

      # Test data with query parameters that need cleaning
      rows = [
        { path: '/some/path?param=value&other=data', referrer: '/referrer/path?ref=source', created_at: Time.current },
        { path: '/clean/path', referrer: nil, created_at: Time.current },
        { path: '/', referrer: '/another?query=string', created_at: Time.current },
      ]

      # Call the actual method that contains the gsub! operations
      cleaned_rows = ActivityLog.scrub(rows)

      # Should have cleaned the query parameters using gsub!
      expect(cleaned_rows[0][:path]).to eq('/some/path')
      expect(cleaned_rows[0][:referrer]).to eq('/referrer/path')
      expect(cleaned_rows[1][:path]).to eq('/clean/path')
      expect(cleaned_rows[1][:referrer]).to be_nil
      expect(cleaned_rows[2][:path]).to eq('/')
      expect(cleaned_rows[2][:referrer]).to eq('/another')
    end
  end
end
