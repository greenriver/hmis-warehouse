###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe 'HUD DateUpdated Tests', type: :model do
  describe 'initial load' do
    before(:all) do
      HmisCsvTwentyTwenty::Utility.clear!
      GrdaWarehouse::Utility.clear!
      @data_source = GrdaWarehouse::DataSource.create(name: 'Green River', short_name: 'GR', source_type: :sftp)
      import_hmis_csv_fixture(
        'drivers/hmis_csv_twenty_twenty/spec/fixtures/files/date_updated_initial',
        data_source: @data_source,
        version: '2020',
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
          'drivers/hmis_csv_twenty_twenty/spec/fixtures/files/date_updated_older',
          data_source: @data_source,
          version: '2020',
          run_jobs: false,
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
          'drivers/hmis_csv_twenty_twenty/spec/fixtures/files/date_updated_same_day',
          data_source: @data_source,
          version: '2020',
          run_jobs: false,
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
          'drivers/hmis_csv_twenty_twenty/spec/fixtures/files/date_updated_newer',
          data_source: @data_source,
          version: '2020',
          run_jobs: false,
        )
      end

      it 'Client One is  changed' do
        client = GrdaWarehouse::Hud::Client.first
        expect(GrdaWarehouse::Hud::Client.count).to eq(1)
        expect(client.full_name).to eq('Client Newer')
      end
    end
  end
end
