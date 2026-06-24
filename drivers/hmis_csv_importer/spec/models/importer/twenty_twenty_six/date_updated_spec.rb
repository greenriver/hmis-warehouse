###
# Copyright Green River Data Group, Inc.
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

    # Regression: mark_incoming_older compares DateUpdated as a local-timezone
    # date, not a UTC date. The DB columns are `timestamp without time zone`
    # holding UTC values (ActiveRecord.default_timezone = :utc). Near midnight
    # UTC, two timestamps on the *same* local day land on *different* UTC days,
    # so a naive CAST(... AS DATE) gives the wrong answer.
    #
    # Setup (America/New_York, UTC-5 in February):
    #
    #   Warehouse record  : 2010-02-01 21:00 ET  →  stored as 2010-02-02 02:00 UTC
    #   Incoming (fixture): 2010-02-01 12:00 ET  →  stored as 2010-02-01 17:00 UTC
    #
    #   Both are Feb 1 in Eastern time.
    #
    #   Naive UTC date cast : Feb 1 < Feb 2 → incoming looks older → BUG
    #   TZ-aware date cast  : Feb 1 = Feb 1 → same day, not older  → correct
    #
    # We also nil out source_hash so mark_unchanged (hash comparison) won't
    # match the record, forcing the code path through mark_incoming_older.
    # The fixture's ExportDate (2020-07-05) is older than the initial import's
    # (2020-07-07), so most_recent_export_for_ds? is false and the date
    # comparison actually runs.
    describe 'timezone boundary: same local day, different UTC day' do
      before(:all) do
        GrdaWarehouse::Hud::Client.first.update_columns(
          DateUpdated: Time.zone.parse('2010-02-01 21:00').utc,
          source_hash: nil,
        )
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
