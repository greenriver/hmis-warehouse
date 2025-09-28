# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisCsvImporter::Importer::ImporterLog, type: :model do
  let(:importer_log) { HmisCsvImporter::Importer::ImporterLog.new }

  describe '#debug_phases method with += operations' do
    it 'calls method that contains multiple += operations for output formatting' do
      # Test the += operations from lines 93-130: formatted_output += "..."

      # Set up phase data to exercise the += operations
      importer_log.instance_variable_set(
        :@phases, {
          'phase1' => {
            'started_at' => Time.current,
            'duration' => 10.5,
            'sql_queries' => {
              'query1' => {
                'duration' => 2.3,
                'query' => 'SELECT * FROM table',
              },
            },
          },
          'phase2' => {
            'started_at' => Time.current,
            # No duration to test the else branch
            'other_key' => 'some_value',
          },
        }
      )

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
      importer_log.instance_variable_set(
        :@phases, {
          'simple_phase' => {
            'started_at' => Time.current,
            'duration' => 5.0,
          },
        }
      )

      result = importer_log.debug_phases(show_sql: false)

      expect(result).to include('simple_phase:')
      expect(result).to include('duration: 5.0 seconds')
    end

    it 'handles phase data with SQL query details' do
      # Test the nested += operations for SQL query formatting
      importer_log.instance_variable_set(
        :@phases, {
          'sql_phase' => {
            'started_at' => Time.current,
            'duration' => 15.2,
            'sql_queries' => {
              'complex_query' => {
                'duration' => 7.8,
                'query' => 'SELECT COUNT(*) FROM enrollments WHERE date > ?',
                'compressed' => true,
              },
              'simple_query' => {
                'duration' => 1.2,
                'query' => 'UPDATE clients SET status = ?',
              },
            },
            'other_sql_data' => {
              'batch_query' => {
                'duration' => 3.5,
                'query' => 'INSERT INTO services VALUES (?)',
                'error' => 'Compression failed',
              },
            },
          },
        }
      )

      result = importer_log.debug_phases(show_sql: true)

      # Should include all the formatted SQL information built with += operations
      expect(result).to include('sql_phase:')
      expect(result).to include('sql_queries:')
      expect(result).to include('complex_query:')
      expect(result).to include('7.8 seconds:')
      expect(result).to include('batch_query:')
      expect(result).to include('3.5 seconds:')
    end

    it 'handles empty phases data' do
      # Test += operations with empty data
      importer_log.instance_variable_set(:@phases, {})

      result = importer_log.debug_phases

      # Should return empty string when no phases to process
      expect(result).to eq('')
    end
  end

  describe 'method calls that exercise string mutations' do
    it 'exercises log_phase method that feeds into debug_phases' do
      # Test the phase logging that creates data for debug_phases to process
      phase_name = 'test_phase'

      expect { importer_log.log_phase(phase_name, duration: 5.0) }.not_to raise_error

      # The logged phase should be accessible for debug_phases to process with +=
      result = importer_log.debug_phases
      expect(result).to include('test_phase:')
    end

    it 'creates new instance without error' do
      new_log = HmisCsvImporter::Importer::ImporterLog.new

      expect(new_log).to be_a(HmisCsvImporter::Importer::ImporterLog)
    end
  end
end
