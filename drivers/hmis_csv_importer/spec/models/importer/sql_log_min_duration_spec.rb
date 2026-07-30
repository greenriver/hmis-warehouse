###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisCsvImporter::Importer::Importer, type: :model do
  # Test design: Tier 3 — the SQL capture threshold feeds benchmark diagnostics;
  # if the env knob stopped being honored, slow-query evidence would silently
  # vanish (or explode) during benchmark runs. Both directions are asserted with
  # a real query of known duration, so the threshold — not fixture absence — is
  # what the passing/failing capture is attributable to.
  def env_key
    HmisCsvImporter::Importer::Importer::SQL_LOG_MIN_DURATION_ENV
  end

  around do |example|
    original = ENV.fetch(env_key, nil)
    example.run
  ensure
    if original.nil?
      ENV.delete(env_key)
    else
      ENV[env_key] = original
    end
  end

  describe '.sql_log_min_duration_ms' do
    it 'defaults to 60 seconds' do
      ENV.delete(env_key)
      expect(described_class.sql_log_min_duration_ms).to eq(60_000)
    end

    it 'honors the environment override' do
      ENV[env_key] = '1500'
      expect(described_class.sql_log_min_duration_ms).to eq(1_500)
    end

    it 'ignores a blank override' do
      ENV[env_key] = ''
      expect(described_class.sql_log_min_duration_ms).to eq(60_000)
    end

    # A malformed value used to reach String#to_i and become 0, which captures
    # every query of the run -- binds included -- into phase_metrics.
    it 'refuses a non-numeric override instead of capturing every query' do
      ENV[env_key] = '1s'
      expect(described_class.sql_log_min_duration_ms).to eq(60_000)
    end

    it 'refuses a zero override' do
      ENV[env_key] = '0'
      expect(described_class.sql_log_min_duration_ms).to eq(60_000)
    end

    it 'refuses a negative override' do
      ENV[env_key] = '-5'
      expect(described_class.sql_log_min_duration_ms).to eq(60_000)
    end

    # Boundary: the floor itself is a legitimate value, so the guard has to be
    # >= rather than >.
    it 'accepts an override at the floor' do
      ENV[env_key] = described_class::MIN_SQL_LOG_MIN_DURATION_MS.to_s
      expect(described_class.sql_log_min_duration_ms).to eq(described_class::MIN_SQL_LOG_MIN_DURATION_MS)
    end
  end

  describe '#with_sql_log' do
    let(:data_source) { GrdaWarehouse::DataSource.create!(name: 'Green River', short_name: 'GR', source_type: :sftp) }
    let(:loader_log) do
      HmisCsvImporter::Loader::LoaderLog.create!(data_source_id: data_source.id, status: :loaded, version: '2026')
    end
    let(:importer) { described_class.new(loader_id: loader_log.id, data_source_id: data_source.id) }

    def run_sleep_query(importer, phase)
      importer.with_sql_log(phase, GrdaWarehouse::Hud::Client) do
        GrdaWarehouseBase.connection.execute('SELECT pg_sleep(0.05)')
      end
    end

    it 'captures queries at or above the configured threshold' do
      ENV[env_key] = '10'
      run_sleep_query(importer, :bench_phase)

      captured = importer.importer_log.reload.phase_metrics['bench_phase']['Client']
      expect(captured.length).to eq(1)
      expect(captured.first['duration']).to be >= 0.04
      decompressed = JSON.parse(Zlib::Inflate.inflate(Base64.decode64(captured.first['compressed_query'])))
      expect(decompressed['sql']).to include('pg_sleep')
    end

    it 'does not capture the same query when it is below the threshold' do
      ENV.delete(env_key)
      run_sleep_query(importer, :bench_phase_quiet)

      phase_metrics = importer.importer_log.reload.phase_metrics
      expect(phase_metrics.to_h['bench_phase_quiet']).to be_nil
    end

    # Pins what a lowered threshold actually persists: bind values are recorded
    # verbatim, so importer binds put client identifiers into phase_metrics.
    # Any change to that (redaction, dropping binds) should be deliberate and
    # turn this red rather than pass unnoticed.
    it 'records bind values, including client identifiers, in the captured payload' do
      ENV[env_key] = '10'
      importer.with_sql_log(:bench_phase_binds, GrdaWarehouse::Hud::Client) do
        GrdaWarehouseBase.connection.exec_query(
          'SELECT pg_sleep(0.05) WHERE $1 = $1',
          'spec',
          [ActiveRecord::Relation::QueryAttribute.new('PersonalID', 'C-SECRET-1', ActiveRecord::Type::String.new)],
        )
      end

      captured = importer.importer_log.reload.phase_metrics['bench_phase_binds']['Client']
      payload = JSON.parse(Zlib::Inflate.inflate(Base64.decode64(captured.first['compressed_query'])))
      expect(payload['binds']).to contain_exactly('name' => 'PersonalID', 'value' => '"C-SECRET-1"')
    end

    # Without a cap the captured array grows with the import, so a low threshold
    # on a real dataset is unbounded in memory and in the stored payload.
    it 'stops capturing once the per-block cap is reached' do
      ENV[env_key] = '10'
      importer.with_sql_log(:bench_phase_capped, GrdaWarehouse::Hud::Client, max_queries: 2) do
        3.times { GrdaWarehouseBase.connection.execute('SELECT pg_sleep(0.05)') }
      end

      captured = importer.importer_log.reload.phase_metrics['bench_phase_capped']['Client']
      expect(captured.length).to eq(2)
    end
  end
end
