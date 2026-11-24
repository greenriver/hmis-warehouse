###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# DDL runs inside the example's transaction and is rolled back with it.
RSpec.describe AppResourceMonitor::PostgresInspector, type: :model do
  let(:connection) { GrdaWarehouseBase.connection }
  let(:inspector) { described_class.new(connection: connection) }

  def stats_for(tablename)
    rows = inspector.sequence_stats.to_a
    rows.find { |row| row['tablename'] == tablename }
  end

  describe '#sequence_stats' do
    before do
      connection.execute(<<~SQL)
        CREATE TABLE seq_spec_parents (id bigserial PRIMARY KEY);
        CREATE TABLE seq_spec_lone_parents (id bigserial PRIMARY KEY);
        CREATE TABLE seq_spec_integer_ids (id serial PRIMARY KEY);
        CREATE TABLE seq_spec_int_children (
          id bigserial PRIMARY KEY,
          parent_id integer REFERENCES seq_spec_parents (id)
        );
        CREATE TABLE seq_spec_small_children (
          id bigserial PRIMARY KEY,
          parent_id smallint REFERENCES seq_spec_parents (id)
        );
        -- Like a pre-PG10 serial: bigint sequence on an integer column
        ALTER SEQUENCE seq_spec_integer_ids_id_seq AS bigint MAXVALUE 9223372036854775807;
        SELECT setval('seq_spec_parents_id_seq', 16384);
      SQL
    end

    it 'uses the sequence max when nothing narrower applies' do
      row = stats_for('seq_spec_lone_parents')

      expect(row['max_value']).to eq('9223372036854775807')
      expect(row['capacity_limited_by']).to eq('sequence')
    end

    it 'caps capacity at the owning column type' do
      row = stats_for('seq_spec_integer_ids')

      expect(row['max_value']).to eq('2147483647')
      expect(row['capacity_limited_by']).to eq('seq_spec_integer_ids.id')
    end

    it 'caps capacity at the narrowest integer column with a foreign key to the owning column' do
      row = stats_for('seq_spec_parents')

      expect(row['column_type']).to eq('bigint')
      expect(row['max_value']).to eq('32767')
      expect(row['capacity_limited_by']).to eq('seq_spec_small_children.parent_id')
      expect(row['pct_used'].to_f).to be_within(0.01).of(50.0)
    end
  end
end
