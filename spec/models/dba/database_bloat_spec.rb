###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dba::DatabaseBloat, type: :model do
  # Bypass ensure_matching_pg_repack_versions! so unit tests don't need a live pg_repack extension
  subject(:db) do
    instance = described_class.allocate
    instance.instance_variable_set(:@ar_base_class, GrdaWarehouseBase)
    instance.instance_variable_set(:@dry_run, false)
    instance
  end

  let(:small_row) do
    {
      'tblname' => 'small_table',
      'schemaname' => 'public',
      'real_size' => '5 GB',
      'real_size_bytes' => (5 * 1024**3).to_s,
      'bloat_size' => 100_000_000,
      'percent_unanalyzed' => 0,
    }
  end

  let(:large_row) do
    {
      'tblname' => 'huge_table',
      'schemaname' => 'public',
      'real_size' => '350 GB',
      'real_size_bytes' => (350 * 1024**3).to_s,
      'bloat_size' => 1_000_000_000,
      'percent_unanalyzed' => 0,
    }
  end

  let(:threshold_row) do
    {
      'tblname' => 'exact_threshold_table',
      'schemaname' => 'public',
      'real_size' => '100 GB',
      'real_size_bytes' => described_class::MAX_REPACK_TABLE_SIZE.to_s,
      'bloat_size' => 500_000_000,
      'percent_unanalyzed' => 0,
    }
  end

  def stub_repack_prerequisites
    allow(db).to receive(:pg_repack_db_version).and_return('1.5.3')
    allow(db).to receive(:binary_available_on_container?).and_return(true)
    allow(db).to receive(:adjust_autovacuum_for)
    allow(db).to receive(:run_system_command).and_return(true)
    stub_const('Dba::DatabaseBloat::MAX_PER_RUN', 100)
  end

  describe '#repack!' do
    context 'when pg_repack is not supported for the base class' do
      it 'logs and returns early without processing any tables' do
        instance = described_class.allocate
        instance.instance_variable_set(:@ar_base_class, HealthBase)
        instance.instance_variable_set(:@dry_run, false)

        expect(instance).not_to receive(:bloated_tables)
        instance.repack!
      end
    end

    context 'when a table exceeds MAX_REPACK_TABLE_SIZE' do
      before do
        allow(db).to receive(:bloated_tables).and_return([large_row, small_row])
        stub_repack_prerequisites
      end

      it 'skips the oversized table with a warning' do
        expect(Rails.logger).to receive(:warn).with(/Skipping pg_repack.*huge_table.*350 GB/)
        db.repack!
      end

      it 'still processes the small table' do
        allow(Rails.logger).to receive(:warn)
        expect(db).to receive(:run_system_command).once
        db.repack!
      end
    end

    context 'when a table is exactly at MAX_REPACK_TABLE_SIZE' do
      before do
        allow(db).to receive(:bloated_tables).and_return([threshold_row])
        stub_repack_prerequisites
      end

      it 'still processes the table (must exceed to skip)' do
        expect(Rails.logger).not_to receive(:warn).with(/Skipping pg_repack/)
        expect(db).to receive(:run_system_command).once
        db.repack!
      end
    end

    context 'when all tables are under MAX_REPACK_TABLE_SIZE' do
      before do
        allow(db).to receive(:bloated_tables).and_return([small_row])
        stub_repack_prerequisites
      end

      it 'processes the table without a skip warning' do
        expect(Rails.logger).not_to receive(:warn).with(/Skipping pg_repack/)
        expect(db).to receive(:run_system_command).once
        db.repack!
      end
    end

    context 'when there are no bloated tables' do
      before { allow(db).to receive(:bloated_tables).and_return([]) }

      it 'does nothing' do
        expect(db).not_to receive(:run_system_command)
        db.repack!
      end
    end
  end

  describe '#quote_pg_identifier' do
    it 'leaves lowercase snake_case identifiers unquoted' do
      expect(db.send(:quote_pg_identifier, 'my_table')).to eq('my_table')
    end

    it 'quotes identifiers with uppercase letters' do
      expect(db.send(:quote_pg_identifier, 'MyTable')).to eq('"MyTable"')
    end

    it 'quotes identifiers starting with a digit' do
      expect(db.send(:quote_pg_identifier, '2024_data')).to eq('"2024_data"')
    end
  end
end
