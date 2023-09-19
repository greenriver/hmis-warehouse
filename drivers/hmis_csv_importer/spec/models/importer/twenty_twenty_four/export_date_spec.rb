###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe 'HUD ExportDate Tests', type: :model do
  # NOTE: date_updated_spec.rb tests test that data isn't changed when imported and the second Export was created before the first.
  # This tests that data is updated regardless of DateUpdated if the ExportDate is newer or the same
  describe 'initial load' do
    before(:all) do
      HmisCsvImporter::Utility.clear!
      GrdaWarehouse::Utility.clear!
      @data_source = GrdaWarehouse::DataSource.create(name: 'Green River', short_name: 'GR', source_type: :sftp)
      import_hmis_csv_fixture(
        'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_four/export_date_fixtures/date_updated_initial',
        version: 'AutoMigrate',
        data_source: @data_source,
        run_jobs: false,
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
          'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_four/export_date_fixtures/date_updated_older',
          version: 'AutoMigrate',
          data_source: @data_source,
          run_jobs: false,
        )
      end

      it 'Client One has not changed' do
        client = GrdaWarehouse::Hud::Client.first
        expect(GrdaWarehouse::Hud::Client.count).to eq(1)
        expect(client.full_name).to eq('Client Older')
      end
    end

    describe 'same day update' do
      before(:all) do
        import_hmis_csv_fixture(
          'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_four/export_date_fixtures/date_updated_same_day',
          version: 'AutoMigrate',
          data_source: @data_source,
          run_jobs: false,
        )
      end

      it 'Client One is changed' do
        client = GrdaWarehouse::Hud::Client.first
        expect(GrdaWarehouse::Hud::Client.count).to eq(1)
        expect(client.full_name).to eq('Client Same')
      end
    end

    describe 'newer update' do
      before(:all) do
        import_hmis_csv_fixture(
          'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_four/export_date_fixtures/date_updated_newer',
          version: 'AutoMigrate',
          data_source: @data_source,
          run_jobs: false,
        )
      end

      it 'Client One is changed' do
        client = GrdaWarehouse::Hud::Client.first
        expect(GrdaWarehouse::Hud::Client.count).to eq(1)
        expect(client.full_name).to eq('Client Newer')
      end
    end
  end
end
