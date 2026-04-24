###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'HUD DateUpdated Tests', type: :model do
  describe 'initial load' do
    before(:all) do
      HmisCsvImporter::Utility.clear!
      GrdaWarehouse::Utility.clear!
      @data_source = GrdaWarehouse::DataSource.create(name: 'Green River', short_name: 'GR', source_type: :sftp)
      import_hmis_csv_fixture(
        'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_six/date_updated_initial',
        data_source: @data_source,
        version: 'AutoMigrate',
        run_jobs: false,
        stop_version: '2026',
      )
    end

    it 'imports Client One' do
      client = GrdaWarehouse::Hud::Client.first
      expect(GrdaWarehouse::Hud::Client.count).to eq(1)
      expect(client.full_name).to eq('Client One')
    end

    describe 'older update' do
      before(:all) do
        import_hmis_csv_fixture(
          'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_six/date_updated_older',
          data_source: @data_source,
          version: 'AutoMigrate',
          run_jobs: false,
          stop_version: '2026',
        )
      end

      it 'Client One is not changed' do
        client = GrdaWarehouse::Hud::Client.first
        expect(GrdaWarehouse::Hud::Client.count).to eq(1)
        expect(client.full_name).to eq('Client One')
      end
    end

    describe 'same day update' do
      before(:all) do
        import_hmis_csv_fixture(
          'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_six/date_updated_same_day',
          data_source: @data_source,
          version: 'AutoMigrate',
          run_jobs: false,
          stop_version: '2026',
        )
      end

      it 'Client One is  changed' do
        client = GrdaWarehouse::Hud::Client.first
        expect(GrdaWarehouse::Hud::Client.count).to eq(1)
        expect(client.full_name).to eq('Client Same')
      end
    end

    describe 'newer update' do
      before(:all) do
        import_hmis_csv_fixture(
          'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_six/date_updated_newer',
          data_source: @data_source,
          version: 'AutoMigrate',
          run_jobs: false,
          stop_version: '2026',
        )
      end

      it 'Client One is  changed' do
        client = GrdaWarehouse::Hud::Client.first
        expect(GrdaWarehouse::Hud::Client.count).to eq(1)
        expect(client.full_name).to eq('Client Newer')
      end
    end

    # Regression test for timezone-aware DateUpdated comparison in mark_incoming_older.
    #
    # mark_incoming_older must compare dates at the application's local timezone
    # granularity, not UTC. Rails stores timestamps as UTC, so two timestamps that
    # fall on the same local day can appear to be on different UTC days near midnight.
    #
    # If the comparison uses a naive CAST(... AS DATE) in PostgreSQL (UTC day
    # boundaries), the incoming record would be considered "older" (wrong), and
    # mark_incoming_older would preserve the warehouse value — silently dropping a
    # valid update.
    #
    # The correct fix uses AT TIME ZONE to shift both timestamps into the
    # application's local timezone before extracting the date.
    #
    # Scenario (Rails timezone = America/New_York, UTC-5 in February):
    #
    #   CSV timestamps are parsed by Time.zone.strptime, so they represent Eastern Time.
    #   PostgreSQL stores them as UTC (timestamp without time zone).
    #
    #   Warehouse DateUpdated : 2010-02-01 21:00 Eastern → stored UTC: 2010-02-02 02:00 (Feb 2)
    #   Incoming  DateUpdated : 2010-02-01 12:00 Eastern → stored UTC: 2010-02-01 17:00 (Feb 1)
    #   (incoming is from the existing date_updated_newer fixture)
    #
    #   Naive CAST(... AS DATE) using stored UTC values:
    #     Feb 1 < Feb 2  → true  → mark_incoming_older fires → unchanged count = 1 (BUG)
    #
    #   Timezone-aware CAST(... AT TIME ZONE 'UTC' AT TIME ZONE 'America/New_York' AS DATE):
    #     Feb 1 Eastern == Feb 1 Eastern → false → apply_updates runs → unchanged count = 0 (correct)
    describe 'timezone boundary: same local day, different UTC day' do
      before(:all) do
        # Push the warehouse DateUpdated to 21:00 ET (= 2010-02-02 02:00 UTC, UTC day Feb 2).
        # Null source_hash so mark_unchanged (hash equality) passes through to mark_incoming_older.
        GrdaWarehouse::Hud::Client.first.update_columns(
          DateUpdated: Time.zone.parse('2010-02-01 21:00').utc,
          source_hash: nil,
        )
        # Re-import date_updated_newer: DateUpdated = 12:00 ET (= 2010-02-01 17:00 UTC, UTC day Feb 1).
        # Its ExportDate (2020-07-05) is older than the previous max (2020-07-07), so
        # most_recent_export_for_ds? returns false and mark_incoming_older runs.
        # Both timestamps fall on Eastern Feb 1, so mark_incoming_older must NOT fire.
        @tz_importer = import_hmis_csv_fixture(
          'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_six/date_updated_newer',
          data_source: @data_source,
          version: 'AutoMigrate',
          run_jobs: false,
          stop_version: '2026',
        )
      end

      it 'does not mark the record as unchanged when both timestamps fall on the same local day' do
        expect(@tz_importer.importer_log.summary['Client.csv']['unchanged']).to eq(0)
      end
    end
  end
end
