###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisCsvImporter::Benchmarking::PgStats, type: :model do
  # Test design: Tier 2 — these counters are the scale-invariant evidence for
  # the write-amplification fixes; wrong deltas would mis-attribute an entire
  # milestone. Delta math is asserted on exact synthetic values; the snapshot
  # is asserted against real inserts on a real table (with a bounded retry for
  # the stats collector's flush lag, which is external timing, not our logic).
  describe '.delta' do
    it 'subtracts per-counter values and drops tables with no changes' do
      before_snapshot = {
        'Disabilities' => { 'n_tup_ins' => 100, 'n_tup_upd' => 50, 'seq_scan' => 7 },
        'Client' => { 'n_tup_ins' => 10, 'n_tup_upd' => 0, 'seq_scan' => 1 },
      }
      after_snapshot = {
        'Disabilities' => { 'n_tup_ins' => 100, 'n_tup_upd' => 5_050, 'seq_scan' => 81 },
        'Client' => { 'n_tup_ins' => 10, 'n_tup_upd' => 0, 'seq_scan' => 1 },
      }

      expect(described_class.delta(before_snapshot, after_snapshot)).to eq(
        'Disabilities' => { 'n_tup_upd' => 5_000, 'seq_scan' => 74 },
      )
    end

    it 'treats tables missing from the before snapshot as zero' do
      after_snapshot = { 'tmp_new_table' => { 'n_tup_ins' => 3, 'n_tup_upd' => 0 } }

      expect(described_class.delta({}, after_snapshot)).to eq(
        'tmp_new_table' => { 'n_tup_ins' => 3 },
      )
    end

    it 'reports negative deltas, such as dead tuples removed by vacuum' do
      before_snapshot = { 'Client' => { 'n_dead_tup' => 500 } }
      after_snapshot = { 'Client' => { 'n_dead_tup' => 2 } }

      expect(described_class.delta(before_snapshot, after_snapshot)).to eq(
        'Client' => { 'n_dead_tup' => -498 },
      )
    end
  end

  describe '#snapshot' do
    # Backends only transmit table stats at transaction end, so the writes
    # must commit for the counters to move — the suite's wrapping transaction
    # would hide them entirely.
    self.use_transactional_tests = false

    after do
      GrdaWarehouse::DataSource.where('name LIKE ?', 'PgStats %').delete_all
    end

    it 'captures cumulative counters that reflect real writes' do
      pg_stats = described_class.new
      before_snapshot = pg_stats.snapshot

      5.times do |i|
        GrdaWarehouse::DataSource.create!(name: "PgStats #{i}", short_name: "PG#{i}", source_type: :sftp)
      end

      # The cumulative statistics system flushes asynchronously (up to ~1s);
      # poll briefly rather than sleeping a fixed amount.
      delta = {}
      25.times do
        delta = described_class.delta(before_snapshot, pg_stats.snapshot)
        break if delta.dig('data_sources', 'n_tup_ins').to_i >= 5

        sleep 0.2
      end

      expect(delta.dig('data_sources', 'n_tup_ins')).to eq(5)
    end
  end

  describe '#other_active_connections' do
    it 'returns a non-negative count excluding this connection' do
      count = described_class.new.other_active_connections
      expect(count).to be_a(Integer)
      expect(count).to be >= 0
    end
  end
end
