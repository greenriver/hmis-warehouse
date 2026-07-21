###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisCsvImporter::Benchmarking::Results, type: :model do
  # Test design: Tier 2 — results JSON is the evidence used to claim performance
  # wins; a mislabeled phase or dropped metric silently invalidates comparisons.
  # Uses a real ImporterLog attribute payload and asserts the exact transformed
  # output, not just presence.
  let(:started_at) { Time.utc(2026, 7, 21, 12, 0, 0) }
  let(:finished_at) { Time.utc(2026, 7, 21, 12, 34, 56) }
  let(:phase_metrics) do
    {
      'pre_process' => {
        'started_at' => '2026-07-21T12:00:01Z',
        'duration' => 12.345,
        'cpu_percentage' => 87,
        'memory_delta' => 2048,
      },
      'process_existing' => {
        'started_at' => '2026-07-21T12:10:00Z',
        'duration' => 100.5,
        'cpu_percentage' => 12,
        'memory_delta' => 0,
        'Disability.involved_warehouse_scope' => [
          { 'compressed_query' => 'abc123', 'duration' => 61.2 },
          { 'compressed_query' => 'def456', 'duration' => 415.0 },
        ],
      },
    }
  end
  let(:summary) do
    {
      'Client.csv' => { 'pre_processed' => 10, 'added' => 2, 'updated' => 1, 'unchanged' => 7, 'removed' => 0 },
    }
  end
  let(:importer_log) do
    HmisCsvImporter::Importer::ImporterLog.new(id: 42, phase_metrics: phase_metrics, summary: summary)
  end
  let(:loader_log) do
    HmisCsvImporter::Loader::LoaderLog.new(id: 43, summary: { 'Client.csv' => { 'secs' => 1.2 } })
  end
  let(:results) do
    described_class.new(
      label: 'My Label',
      dataset: { name: 'ds', path: '/tmp/ds', content_hash: 'cafe' },
      data_source_id: 7,
      started_at: started_at,
      finished_at: finished_at,
      importer_log: importer_log,
      loader_log: loader_log,
      git: { sha: 'deadbeef', branch: 'a-branch', dirty: false },
    )
  end

  describe 'run_id' do
    it 'combines the start timestamp and a sanitized label' do
      expect(results.run_id).to eq('20260721_120000_my_label')
    end

    it 'omits the label segment when no label is given' do
      unlabeled = described_class.new(
        label: nil,
        dataset: {},
        data_source_id: 7,
        started_at: started_at,
        finished_at: finished_at,
        importer_log: importer_log,
        git: {},
      )
      expect(unlabeled.run_id).to eq('20260721_120000')
    end
  end

  describe 'to_h' do
    it 'transforms phase metrics into durations plus slow-query summaries' do
      expect(results.to_h[:phases]).to eq(
        'pre_process' => {
          'started_at' => '2026-07-21T12:00:01Z',
          'duration' => 12.345,
          'cpu_percentage' => 87,
          'memory_delta' => 2048,
        },
        'process_existing' => {
          'started_at' => '2026-07-21T12:10:00Z',
          'duration' => 100.5,
          'cpu_percentage' => 12,
          'memory_delta' => 0,
          'slow_queries' => {
            'Disability.involved_warehouse_scope' => [61.2, 415.0],
          },
        },
      )
    end

    it 'mirrors the per-file importer summary verbatim' do
      expect(results.to_h[:per_file]).to eq(summary)
    end

    it 'records run identity, timing, logs, and git information' do
      hash = results.to_h
      expect(hash[:run_id]).to eq('20260721_120000_my_label')
      expect(hash[:label]).to eq('My Label')
      expect(hash[:dataset]).to eq(name: 'ds', path: '/tmp/ds', content_hash: 'cafe')
      expect(hash[:data_source_id]).to eq(7)
      expect(hash[:started_at]).to eq('2026-07-21T12:00:00Z')
      expect(hash[:finished_at]).to eq('2026-07-21T12:34:56Z')
      expect(hash[:total_seconds]).to eq(2096.0)
      expect(hash[:importer_log_id]).to eq(42)
      expect(hash[:loader_log_id]).to eq(43)
      expect(hash[:loader_summary]).to eq('Client.csv' => { 'secs' => 1.2 })
      expect(hash[:git]).to eq(sha: 'deadbeef', branch: 'a-branch', dirty: false)
    end

    it 'records the runtime environment versions' do
      versions = results.to_h[:versions]
      expect(versions[:ruby]).to eq(RUBY_VERSION)
      expect(versions[:rails]).to eq(Rails.version)
      expect(versions[:postgres]).to eq(GrdaWarehouseBase.connection.select_value('SHOW server_version'))
    end
  end

  describe 'write!' do
    it 'writes pretty JSON named by run_id and returns the path' do
      Dir.mktmpdir do |dir|
        path = results.write!(dir: dir)

        expect(path).to eq(File.join(dir, '20260721_120000_my_label.json'))
        parsed = JSON.parse(File.read(path))
        expect(parsed['run_id']).to eq('20260721_120000_my_label')
        expect(parsed['phases']['pre_process']['duration']).to eq(12.345)
      end
    end

    it 'creates the results directory when missing' do
      Dir.mktmpdir do |dir|
        nested = File.join(dir, 'does', 'not', 'exist')
        path = results.write!(dir: nested)
        expect(File.exist?(path)).to eq(true)
      end
    end
  end

  describe '.git_info' do
    it 'reports the current sha, branch, and dirty state' do
      skip 'git not available in this environment' unless system('git -C . rev-parse --verify HEAD > /dev/null 2>&1')

      info = HmisCsvImporter::Benchmarking.git_info
      expect(info[:sha]).to eq(`git -C . rev-parse HEAD`.strip)
      expect(info[:branch]).to eq(`git -C . rev-parse --abbrev-ref HEAD`.strip)
      expect(info[:dirty]).to be_in([true, false])
    end
  end
end
