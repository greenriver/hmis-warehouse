# frozen_string_literal: false

require 'rails_helper'

RSpec.describe HmisCsvImporter::Importer::ImporterLog, type: :model do
  let(:importer_log) { HmisCsvImporter::Importer::ImporterLog.new }

  describe '#debug_phases method with += operations' do
    it 'calls method that contains multiple += operations for output formatting' do
      # Test the += operations from lines 93-130: formatted_output += "..."

      # Set up phase data to exercise the += operations
      # Note: phase_metrics is the actual attribute name, and SQL queries must be arrays
      importer_log.phase_metrics = {
        'phase1' => {
          'started_at' => Time.current.to_s,
          'duration' => 10.5,
          'sql_queries' => [
            {
              'duration' => 2.3,
              'compressed_query' => Base64.encode64(Zlib::Deflate.deflate({ 'sql' => 'SELECT * FROM table', 'binds' => [] }.to_json)),
            },
          ],
        },
        'phase2' => {
          'started_at' => Time.current.to_s,
          # No duration to test the else branch
        },
      }

      # Call the actual method that contains the += operations
      result = importer_log.debug_phases(show_sql: true)

      # Should return a formatted string built with += operations
      expect(result).to be_a(String)
      expect(result).to include('phase1:')
      expect(result).to include('phase2:')
      expect(result).to include('duration: 10.5 seconds')
      expect(result).to include('duration: incomplete')
    end

    it 'handles phase data without SQL queries' do
      # Test += operations with minimal phase data
      importer_log.phase_metrics = {
        'simple_phase' => {
          'started_at' => Time.current.to_s,
          'duration' => 5.0,
        },
      }

      result = importer_log.debug_phases(show_sql: false)

      expect(result).to include('simple_phase:')
      expect(result).to include('duration: 5.0 seconds')
    end

    it 'handles phase data with SQL query details' do
      # Test the nested += operations for SQL query formatting
      importer_log.phase_metrics = {
        'sql_phase' => {
          'started_at' => Time.current.to_s,
          'duration' => 15.2,
          'sql_queries' => [
            {
              'duration' => 7.8,
              'compressed_query' => Base64.encode64(Zlib::Deflate.deflate({ 'sql' => 'SELECT COUNT(*) FROM enrollments WHERE date > ?', 'binds' => [] }.to_json)),
            },
            {
              'duration' => 1.2,
              'compressed_query' => Base64.encode64(Zlib::Deflate.deflate({ 'sql' => 'UPDATE clients SET status = ?', 'binds' => [] }.to_json)),
            },
          ],
          'other_sql_data' => [
            {
              'duration' => 3.5,
              'compressed_query' => Base64.encode64(Zlib::Deflate.deflate({ 'sql' => 'INSERT INTO services VALUES (?)', 'binds' => [] }.to_json)),
            },
          ],
        },
      }

      result = importer_log.debug_phases(show_sql: true)

      # Should include all the formatted SQL information built with += operations
      expect(result).to include('sql_phase:')
      expect(result).to include('sql_queries:')
      expect(result).to include('query1:')
      expect(result).to include('7.8 seconds:')
      expect(result).to include('other_sql_data:')
      expect(result).to include('3.5 seconds:')
    end

    it 'handles empty phases data' do
      # Test += operations with empty data
      importer_log.phase_metrics = {}

      result = importer_log.debug_phases

      # Should return nil when no phases to process (method returns early)
      expect(result).to be_nil
    end
  end

  describe 'method calls that exercise string mutations' do
    it 'exercises log_phase method that feeds into debug_phases' do
      # Test the phase logging that creates data for debug_phases to process
      # Note: log_phase requires save!, so we need a persisted record
      data_source = create(:grda_warehouse_data_source)
      saved_log = create(:hmis_csv_importer_log, data_source: data_source)

      phase_name = 'test_phase'

      expect { saved_log.log_phase(phase_name, duration: 5.0, started_at: Time.current.to_s) }.not_to raise_error

      # The logged phase should be accessible for debug_phases to process with +=
      result = saved_log.debug_phases
      expect(result).to include('test_phase:')
    end

    it 'creates new instance without error' do
      new_log = HmisCsvImporter::Importer::ImporterLog.new

      expect(new_log).to be_a(HmisCsvImporter::Importer::ImporterLog)
    end
  end
end
