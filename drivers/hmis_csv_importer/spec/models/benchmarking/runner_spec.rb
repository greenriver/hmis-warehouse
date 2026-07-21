###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisCsvImporter::Benchmarking::Runner, type: :model do
  # Test design: Tier 2 — the runner produces the evidence for perf claims and
  # must faithfully record what the real import pipeline did. Full real import
  # of a small fixture (no mocks), asserting the emitted JSON against the
  # DB-recorded importer log. Production refusal is Tier 1 safety: the runner
  # drives destructive seeding/restores in later issues, so it must provably
  # not run in production — asserted by observing no import side effects.
  let(:fixture_path) { 'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_six/incoming_older_processing' }

  describe 'production refusal' do
    let(:data_source) { GrdaWarehouse::DataSource.create!(name: 'Green River', short_name: 'GR', source_type: :sftp) }

    it 'raises before importing anything' do
      data_source
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production'))

      Dir.mktmpdir do |results_dir|
        runner = described_class.new(
          dataset_path: fixture_path,
          data_source_id: data_source.id,
          results_dir: results_dir,
        )
        expect { runner.run! }.to raise_error(/production/)
        expect(Dir.children(results_dir)).to be_empty
      end
      expect(HmisCsvImporter::Loader::LoaderLog.count).to eq(0)
      expect(HmisCsvImporter::Importer::ImporterLog.count).to eq(0)
    end
  end

  describe 'git identity refusal' do
    let(:data_source) { GrdaWarehouse::DataSource.create!(name: 'Green River', short_name: 'GR', source_type: :sftp) }

    around do |example|
      sha_env = HmisCsvImporter::Benchmarking::GIT_SHA_ENV
      branch_env = HmisCsvImporter::Benchmarking::GIT_BRANCH_ENV
      original = [ENV.fetch(sha_env, nil), ENV.fetch(branch_env, nil)]
      ENV.delete(sha_env)
      ENV.delete(branch_env)
      example.run
    ensure
      ENV[sha_env] = original[0] if original[0]
      ENV[branch_env] = original[1] if original[1]
    end

    it 'raises before importing when the code version cannot be determined' do
      data_source
      allow(Open3).to receive(:capture3).and_raise(Errno::ENOENT, 'git')

      Dir.mktmpdir do |results_dir|
        runner = described_class.new(
          dataset_path: fixture_path,
          data_source_id: data_source.id,
          results_dir: results_dir,
        )
        expect { runner.run! }.to raise_error(/HMIS_BENCHMARK_GIT_SHA/)
        expect(Dir.children(results_dir)).to be_empty
      end
      expect(HmisCsvImporter::Loader::LoaderLog.count).to eq(0)
      expect(HmisCsvImporter::Importer::ImporterLog.count).to eq(0)
    end
  end

  describe 'a full benchmark run' do
    before(:all) do
      HmisCsvImporter::Utility.clear!
      GrdaWarehouse::Utility.clear!
      @data_source = GrdaWarehouse::DataSource.create!(name: 'Green River', short_name: 'GR', source_type: :sftp)
      GrdaWarehouse::DataSource.create!(name: 'Warehouse', short_name: 'W')
      @results_dir = Dir.mktmpdir
      @result_path = HmisCsvImporter::Benchmarking::Runner.new(
        dataset_path: 'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_six/incoming_older_processing',
        data_source_id: @data_source.id,
        label: 'spec run',
        results_dir: @results_dir,
      ).run!
      @json = JSON.parse(File.read(@result_path))
      @importer_log = HmisCsvImporter::Importer::ImporterLog.order(:id).last
    end

    after(:all) do
      FileUtils.rm_rf(@results_dir)
      HmisCsvImporter::Utility.clear!
      GrdaWarehouse::Utility.clear!
    end

    it 'imports into the requested data source' do
      expect(@importer_log.data_source_id).to eq(@data_source.id)
      expect(@json['data_source_id']).to eq(@data_source.id)
      expect(GrdaWarehouse::Hud::Client.where(data_source_id: @data_source.id).count).to be > 0
    end

    it 'records real phase durations that match the importer log' do
      expect(@json['phases'].keys).to include('pre_process', 'mark_tree_as_dead', 'add_new_data', 'process_existing')
      pre_process = @json['phases']['pre_process']
      expect(pre_process['duration']).to be_a(Float)
      expect(pre_process['duration']).to be > 0
      expect(pre_process['duration']).to eq(@importer_log.phase_metrics['pre_process']['duration'])
    end

    it 'mirrors the importer per-file summary' do
      expect(@json['per_file']).to eq(@importer_log.summary)
      expect(@json['per_file']['Client.csv']['added']).to eq(@importer_log.summary['Client.csv']['added'])
    end

    it 'records dataset identity from the fixture content' do
      dataset = HmisCsvImporter::Benchmarking::Dataset.new(
        'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_six/incoming_older_processing',
      )
      expect(@json['dataset']['name']).to eq('incoming_older_processing')
      expect(@json['dataset']['content_hash']).to eq(dataset.content_hash)
    end

    it 'names the results file with the run id and label' do
      expect(File.basename(@result_path)).to match(/\A\d{8}_\d{6}_spec_run\.json\z/)
      expect(@json['run_id']).to eq(File.basename(@result_path, '.json'))
    end

    it 'links the loader and importer logs and mirrors the loader summary' do
      loader_log = HmisCsvImporter::Loader::LoaderLog.order(:id).last
      expect(@json['importer_log_id']).to eq(@importer_log.id)
      expect(@json['loader_log_id']).to eq(loader_log.id)
      expect(loader_log.importer_log_id).to eq(@importer_log.id)
      expect(@json['loader_summary']).to eq(loader_log.summary)
    end
  end
end
