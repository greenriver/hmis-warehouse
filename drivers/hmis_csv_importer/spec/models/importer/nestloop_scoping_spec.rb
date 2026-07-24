###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisCsvImporter::Importer::Importer, type: :model do
  # Test design: Tier 2 — issue 9211: with_sql_log used to disable nested-loop
  # joins for entire import phases, forcing the 5k-row batch UPDATEs added by
  # PR #6388 into whole-table join plans (~7s per batch instead of PK lookups).
  # The planner guard belongs only on the set-based involved_warehouse_scope
  # statements PR #5162 originally protected. This asserts the observable
  # session state inside the block; re-wrapping the whole phase turns it red.
  let(:data_source) { GrdaWarehouse::DataSource.create!(name: 'Green River', short_name: 'GR', source_type: :sftp) }
  let(:loader_log) do
    HmisCsvImporter::Loader::LoaderLog.create!(data_source_id: data_source.id, status: :loaded, version: '2026')
  end
  let(:importer) { described_class.new(loader_id: loader_log.id, data_source_id: data_source.id) }

  describe '#with_sql_log' do
    it 'runs its block with nested-loop joins still available' do
      setting = importer.with_sql_log(:nestloop_check, GrdaWarehouse::Hud::Client) do
        GrdaWarehouseBase.connection.select_value('SHOW enable_nestloop')
      end

      expect(setting).to eq('on')
    end
  end

  # Test design: Tier 3 — planner-guard placement in remove_pending_deletes.
  # The multi-join set-based statements need the guard (PR #5162); the batched
  # primary-key UPDATEs must not get it (issue 9211). A real import runs with a
  # sql.active_record probe that reads SHOW enable_nestloop on the statement's
  # own connection at execution time, so re-scoping any guard turns this red;
  # the negative case (batch UPDATE unguarded) is asserted from the same run.
  describe 'remove_pending_deletes planner guards' do
    PROBE_PATTERNS = {
      # source_hash renders as a bind ($1) when prepared statements are on and
      # as a NULL literal when they are off; match both.
      client_source_hash_update: /\AUPDATE "Client" SET "source_hash" = (?:\$\d+|NULL) WHERE .* INNER JOIN/m,
      pending_deletes_materialization: /\ACREATE TEMP TABLE "tmp_pending_deletes_/,
      pending_deletes_batch_update: /\AUPDATE .* SELECT id FROM "tmp_pending_deletes_/m,
    }.freeze

    before(:all) do
      HmisCsvImporter::Utility.clear!
      GrdaWarehouse::Utility.clear!
      @settings = {}
      probe = lambda do |event|
        conn = event.payload[:connection]
        next if conn.nil?

        PROBE_PATTERNS.each do |key, pattern|
          next if @settings.key?(key)
          next unless event.payload[:sql].match?(pattern)

          @settings[key] = conn.select_value('SHOW enable_nestloop')
        end
      end

      ActiveSupport::Notifications.subscribed(probe, 'sql.active_record') do
        import_hmis_csv_fixture(
          'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_six/incoming_older_processing',
          data_source: GrdaWarehouse::DataSource.create!(name: 'Green River', short_name: 'GR', source_type: :sftp),
          version: 'AutoMigrate',
          run_jobs: false,
        )
      end
    end

    after(:all) do
      HmisCsvImporter::Utility.clear!
      GrdaWarehouse::Utility.clear!
    end

    it 'guards the PersonalID multi-join source_hash update' do
      expect(@settings.fetch(:client_source_hash_update)).to eq('off')
    end

    it 'guards the pending-deletes temp table materialization' do
      expect(@settings.fetch(:pending_deletes_materialization)).to eq('off')
    end

    it 'leaves the batched pending-deletes UPDATE unguarded' do
      expect(@settings.fetch(:pending_deletes_batch_update)).to eq('on')
    end
  end
end
