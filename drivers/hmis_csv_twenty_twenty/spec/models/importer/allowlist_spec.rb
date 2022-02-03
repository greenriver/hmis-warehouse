###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe HmisCsvTwentyTwenty, type: :model do
  describe 'When importing enrollments with one allowed project' do
    before(:all) do
      HmisCsvTwentyTwenty::Utility.clear!
      GrdaWarehouse::Utility.clear!

      @data_source = GrdaWarehouse::DataSource.create(name: 'Green River', short_name: 'GR', source_type: :sftp)
      GrdaWarehouse::WhitelistedProjectsForClients.delete_all
      GrdaWarehouse::WhitelistedProjectsForClients.create(ProjectID: 'ALLOW', data_source_id: @data_source.id)

      import_hmis_csv_fixture(
        'drivers/hmis_csv_twenty_twenty/spec/fixtures/files/allowed_projects',
        version: 'AutoDetect',
        data_source: @data_source,
        run_jobs: false,
        allowed_projects: true,
      )
    end

    it 'the database will have two source clients' do
      expect(GrdaWarehouse::Hud::Client.source.count).to eq(2)
    end

    it 'the database will have fourteen enrollments' do
      expect(GrdaWarehouse::Hud::Enrollment.count).to eq(14)
    end

    it 'the database will not include third client' do
      expect(GrdaWarehouse::Hud::Client.source.pluck(:PersonalID)).not_to include('C-3')
    end

    describe 'when importing updated enrollment data with an allowlist' do
      before(:all) do
        import_hmis_csv_fixture(
          'drivers/hmis_csv_twenty_twenty/spec/fixtures/files/allowed_projects',
          version: 'AutoDetect',
          data_source: @data_source,
          run_jobs: false,
          allowed_projects: true,
        )
      end

      it 'it doesn\'t add additional clients' do
        expect(GrdaWarehouse::Hud::Client.source.count).to eq(2)
      end

      it 'the database will not include third client' do
        expect(GrdaWarehouse::Hud::Client.source.pluck(:PersonalID)).not_to include('C-3')
      end
    end
  end # end describe enrollments
end
