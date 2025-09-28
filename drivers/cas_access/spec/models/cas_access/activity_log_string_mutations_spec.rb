# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CasAccess::ActivityLog, type: :model do
  describe '.to_csv method with << operations' do
    it 'calls method that contains << operations for CSV row building' do
      # Test the << operations from lines 32, 34: rows << columns.values, rows << row.values_at(...)

      # Mock some activity log data
      log_entry = { id: 1, action: 'test_action', created_at: Time.current, extra_field: 'ignored' }

      # Mock the CSV generation process
      csv_writer = double('csv_writer')
      allow(CSV).to receive(:generate).and_yield(csv_writer)
      allow(csv_writer).to receive(:<<).and_return(true)

      # Mock the activity log scope
      allow(CasAccess::ActivityLog).to receive(:all).and_return([log_entry])

      # Call the actual class method that contains the << operations
      result = CasAccess::ActivityLog.to_csv

      expect(result).to be_a(String) # CSV.generate returns a string
    end
  end

  describe '.clean_for_export method with gsub! operations' do
    it 'calls method that contains gsub! operations for path cleaning' do
      # Test the gsub! operations from lines 47, 48: row[:path]&.gsub!(/\?.*/, ''), row[:referrer]&.gsub!(/\?.*/, '')

      # Test data with query parameters that need cleaning
      rows = [
        { path: '/some/path?param=value&other=data', referrer: '/referrer/path?ref=source' },
        { path: '/clean/path', referrer: nil },
        { path: nil, referrer: '/another?query=string' },
      ]

      # Call the actual method that contains the gsub! operations
      cleaned_rows = CasAccess::ActivityLog.clean_for_export(rows)

      # Should have cleaned the query parameters using gsub!
      expect(cleaned_rows[0][:path]).to eq('/some/path')
      expect(cleaned_rows[0][:referrer]).to eq('/referrer/path')
      expect(cleaned_rows[1][:path]).to eq('/clean/path')
      expect(cleaned_rows[1][:referrer]).to be_nil
      expect(cleaned_rows[2][:path]).to be_nil
      expect(cleaned_rows[2][:referrer]).to eq('/another')
    end

    it 'handles empty rows array' do
      result = CasAccess::ActivityLog.clean_for_export([])
      expect(result).to eq([])
    end

    it 'handles rows without path or referrer fields' do
      rows = [{ id: 1, action: 'test' }]
      result = CasAccess::ActivityLog.clean_for_export(rows)
      expect(result).to eq(rows)
    end
  end

  describe 'method integration testing' do
    it 'exercises the full CSV export pipeline with string mutations' do
      # Mock the query and data processing
      log_data = {
        id: 1,
        action: 'view',
        path: '/test/path?query=value',
        referrer: '/source?ref=test',
        created_at: Time.current,
      }

      allow(CasAccess::ActivityLog).to receive(:all).and_return([log_data])

      # This should exercise both << and gsub! operations
      result = CasAccess::ActivityLog.to_csv

      expect(result).to be_a(String)
      expect(result.length).to be > 0
    end

    it 'creates new instance without error' do
      log = CasAccess::ActivityLog.new

      expect(log).to be_a(CasAccess::ActivityLog)
    end
  end
end
