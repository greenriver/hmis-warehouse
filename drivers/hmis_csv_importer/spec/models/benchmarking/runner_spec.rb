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

  # Counts settling calls without replacing behavior, so the real counters are
  # still gathered. A subclass rather than a spy because the run happens in
  # before(:all), where rspec-mocks is unavailable.
  def self.counting_pg_stats_class
    Class.new(HmisCsvImporter::Benchmarking::PgStats) do
      def settled_snapshot_calls
        @settled_snapshot_calls || 0
      end

      def settled_snapshot(...)
        @settled_snapshot_calls = settled_snapshot_calls + 1
        super
      end
    end
  end

  describe 'a full benchmark run' do
    before(:all) do
      # Supply the code version through the env overrides (the QA path); CI
      # spec containers cannot reliably resolve identity from the git binary.
      @env_keys = [HmisCsvImporter::Benchmarking::GIT_SHA_ENV, HmisCsvImporter::Benchmarking::GIT_BRANCH_ENV]
      @env_original = @env_keys.map { |key| ENV.fetch(key, nil) }
      ENV[HmisCsvImporter::Benchmarking::GIT_SHA_ENV] = 'spec-sha'
      ENV[HmisCsvImporter::Benchmarking::GIT_BRANCH_ENV] = 'spec-branch'
      HmisCsvImporter::Utility.clear!
      GrdaWarehouse::Utility.clear!
      @data_source = GrdaWarehouse::DataSource.create!(name: 'Green River', short_name: 'GR', source_type: :sftp)
      GrdaWarehouse::DataSource.create!(name: 'Warehouse', short_name: 'W')
      @results_dir = Dir.mktmpdir
      # Captured before the run so the dataset's recorded identity, and the
      # dataset directory itself, are compared against pre-import state. The
      # importer writes a zip into whatever directory it is handed, so a hash
      # taken after the run would agree with the recorded one either way.
      dataset_before = HmisCsvImporter::Benchmarking::Dataset.new(
        'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_six/incoming_older_processing',
      )
      @csv_dir = dataset_before.csv_dir
      @csv_dir_children_before = Dir.children(@csv_dir).sort
      @content_hash_before = dataset_before.content_hash
      @pg_stats = self.class.counting_pg_stats_class.new
      @result_path = HmisCsvImporter::Benchmarking::Runner.new(
        dataset_path: 'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_six/incoming_older_processing',
        data_source_id: @data_source.id,
        label: 'spec run',
        results_dir: @results_dir,
        pg_stats: @pg_stats,
      ).run!
      @json = JSON.parse(File.read(@result_path))
      @importer_log = HmisCsvImporter::Importer::ImporterLog.order(:id).last
    end

    after(:all) do
      @env_keys.zip(@env_original).each { |key, value| value ? ENV[key] = value : ENV.delete(key) }
      FileUtils.rm_rf(@results_dir)
      HmisCsvImporter::Utility.clear!
      GrdaWarehouse::Utility.clear!
    end

    it 'records the env-provided git identity' do
      expect(@json['git']).to eq('sha' => 'spec-sha', 'branch' => 'spec-branch', 'dirty' => nil)
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

    it 'records dataset identity from the fixture content as it was before the run' do
      expect(@json['dataset']['name']).to eq('incoming_older_processing')
      expect(@json['dataset']['content_hash']).to eq(@content_hash_before)
    end

    # Importers::HmisAutoMigrate::Local writes a <ds_id>_<timestamp>.zip into the
    # directory it is given and never removes it, so importing straight from the
    # dataset would leave residue in the repo and permanently change the content
    # hash that keys every past result. Runner copies to a temp dir to avoid it.
    it 'imports from a disposable copy, leaving the dataset directory untouched' do
      expect(Dir.children(@csv_dir).sort).to eq(@csv_dir_children_before)
      expect(HmisCsvImporter::Benchmarking::Dataset.new(
        'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_six/incoming_older_processing',
      ).content_hash).to eq(@content_hash_before)
    end

    it 'names the results file with the run id and label' do
      expect(File.basename(@result_path)).to match(/\A\d{8}_\d{6}_spec_run\.json\z/)
      expect(@json['run_id']).to eq(File.basename(@result_path, '.json'))
    end

    it 'records database write counters for warehouse and staging tables' do
      client_added = @importer_log.summary['Client.csv']['added']
      expect(client_added).to be > 0
      expect(@json['pg_stats']['Client']['n_tup_ins']).to be >= client_added
      expect(@json['pg_stats']['hmis_2026_clients']['n_tup_ins']).to be >= @importer_log.summary['Client.csv']['pre_processed']
    end

    # Lower bounds alone cannot see over-counting, which is the failure mode the
    # settled snapshots exist to prevent: counters flushed late from earlier
    # activity land inside the window and inflate every delta. The database is
    # idle apart from this run, so the insert delta has to stay near the rows the
    # import reports.
    it 'does not attribute unrelated writes to the run' do
      client_added = @importer_log.summary['Client.csv']['added']
      expect(@json['pg_stats']['Client']['n_tup_ins']).to be <= client_added * 3
    end

    # Postgres flushes table stats asynchronously, so an unsettled snapshot at
    # either end silently shifts the window: writes from before the run land
    # inside it, and the run's own tail lands outside. On an idle database that
    # produces no difference in the recorded numbers, so the bound above cannot
    # see it -- the settling itself is the only observable.
    it 'settles the counters at both ends of the run' do
      expect(@pg_stats.settled_snapshot_calls).to eq(2)
    end

    it 'records concurrent connection activity' do
      expect(@json['other_active_connections']['start']).to be_a(Integer)
      expect(@json['other_active_connections']['finish']).to be_a(Integer)
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
