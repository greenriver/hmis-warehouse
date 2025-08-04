# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AppResourceMonitor::Report, type: :model do
  describe '#export_to_csv' do
    let(:report) { described_class.new }
    let(:temp_directory) { Dir.mktmpdir }
    let(:timestamp) { '20241201120000' }
    let!(:data_source) { create(:grda_warehouse_data_source) }

    before do
      allow(report).to receive(:now).and_return(Time.parse('2024-12-01 12:00:00'))

      # Create some HUD records to ensure the inspectors return data
      create_hud_test_data
    end

    after do
      FileUtils.remove_entry(temp_directory) if Dir.exist?(temp_directory)
    end

    it 'exports CSV files' do
      report.export_to_csv(include_structure_files: false) do |dir|
        expect(Dir.exist?(dir)).to be true

        # Verify CSV files are created
        csv_files = Dir.glob(File.join(dir, '*.csv'))
        expect(csv_files).not_to be_empty

        collect_results = report.send(:collect_results)
        expected_csv_files = []

        collect_results.keys.each do |name|
          expected_csv_files << "#{name}-#{timestamp}.csv"
        end

        expect(csv_files.map { |f| File.basename(f) }).to match_array(expected_csv_files)
      end
    end

    it 'exports CSV files when include_structure_files is true' do
      report.export_to_csv(include_structure_files: true) do |dir|
        expect(Dir.exist?(dir)).to be true

        # Verify CSV files are created
        csv_files = Dir.glob(File.join(dir, '*.csv'))
        expect(csv_files).not_to be_empty

        collect_results = report.send(:collect_results)
        expected_csv_files = []

        collect_results.keys.each do |name|
          expected_csv_files << "#{name}-#{timestamp}.csv"
        end

        expect(csv_files.map { |f| File.basename(f) }).to match_array(expected_csv_files)
      end
    end

    it 'does not export structure files when include_structure_files is false' do
      report.export_to_csv(include_structure_files: false) do |dir|
        expect(Dir.exist?(dir)).to be true

        # Verify structure file copies are created
        structure_files = Dir.glob(File.join(dir, '*.sql'))

        expected_structure_files = []

        expect(structure_files.map { |f| File.basename(f) }).to match_array(expected_structure_files)
      end
    end

    it 'exports structure files when include_structure_files is true' do
      report.export_to_csv(include_structure_files: true) do |dir|
        expect(Dir.exist?(dir)).to be true

        # Verify structure file copies are created
        structure_files = Dir.glob(File.join(dir, '*.sql'))

        structure_files_to_copy = report.send(:structure_files)
        expected_structure_files = []

        structure_files_to_copy.keys.each do |name|
          expected_structure_files << "#{name}-#{timestamp}.sql"
        end

        expect(structure_files.map { |f| File.basename(f) }).to match_array(expected_structure_files)
      end
    end
  end

  describe '#structure_files' do
    let(:report) { described_class.new }

    it 'returns expected structure file paths' do
      files = report.send(:structure_files)

      expect(files.keys).to match_array(['app_structure', 'warehouse_structure', 'reporting_structure', 'health_structure'])

      expect(files['app_structure']).to end_with('db/structure.sql')
      expect(files['warehouse_structure']).to end_with('db/warehouse_structure.sql')
      expect(files['reporting_structure']).to end_with('db/reporting_structure.sql')
      expect(files['health_structure']).to end_with('db/health_structure.sql')
    end
  end

  describe '#collect_results' do
    let(:report) { described_class.new }
    let!(:data_source) { create(:grda_warehouse_data_source) }

    before do
      create_hud_test_data
    end

    it 'returns expected CSV data keys' do
      results = report.send(:collect_results)

      expect(results.keys).to match_array(
        [
          'postgres_database_stats',
          'postgres_table_stats',
          'postgres_toast_stats',
          'postgres_index_stats',
          'app_record_stats',
          'app_activity',
          'hud_client_references',
          'hud_enrollment_references',
          'hud_project_references',
          'duplicate_hud_ids',
        ],
      )
    end

    it 'returns arrays for CSV data' do
      results = report.send(:collect_results)

      # Check that CSV data is returned as arrays
      expect(results['postgres_database_stats']).to be_an(Array)
      expect(results['postgres_table_stats']).to be_an(Array)
      expect(results['postgres_toast_stats']).to be_an(Array)
      expect(results['postgres_index_stats']).to be_an(Array)
      expect(results['app_record_stats']).to be_an(Array)
      expect(results['app_activity']).to be_an(Array)
      expect(results['hud_client_references']).to be_an(Array)
      expect(results['hud_enrollment_references']).to be_an(Array)
      expect(results['hud_project_references']).to be_an(Array)
      expect(results['duplicate_hud_ids']).to be_an(Array)
    end
  end

  private

  def create_hud_test_data
    # Create some basic HUD records to ensure the inspectors have data to work with
    # This creates minimal test data that should allow the inspectors to return results

    # Create a client if the model exists
    return unless defined?(GrdaWarehouse::Hud::Client)

    client = create(:grda_warehouse_hud_client, data_source: data_source)

    # Create an enrollment if the model exists
    if defined?(GrdaWarehouse::Hud::Enrollment)
      create(:grda_warehouse_hud_enrollment,
             data_source: data_source,
             personal_id: client.personal_id)
    end

    # Create a project if the model exists
    create(:grda_warehouse_hud_project, data_source: data_source) if defined?(GrdaWarehouse::Hud::Project)
  end
end
