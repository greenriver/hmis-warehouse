###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe HmisCsvTwentyTwenty, type: :model do
  describe 'When importing clients and de-identifying' do
    before(:all) do
      HmisCsvTwentyTwenty::Utility.clear!
      GrdaWarehouse::Utility.clear!
      @data_source = GrdaWarehouse::DataSource.create(name: 'Green River', short_name: 'GR', source_type: :sftp)
      import_hmis_csv_fixture(
        'drivers/hmis_csv_twenty_twenty/spec/fixtures/files/allowed_projects',
        data_source: @data_source,
        version: '2020',
        deidentified: true,
        run_jobs: false,
      )
    end

    it 'the database will have two source clients' do
      expect(GrdaWarehouse::Hud::Client.source.count).to eq(3)
    end

    it 'the database will have fourteen enrollments' do
      expect(GrdaWarehouse::Hud::Enrollment.count).to eq(15)
    end

    it 'the database will include third client' do
      expect(GrdaWarehouse::Hud::Client.source.pluck(:PersonalID)).to include('C-3')
    end

    it 'the client first names should not include the word Client' do
      expect(GrdaWarehouse::Hud::Client.source.pluck(:FirstName).to_s).not_to include('Client')
    end

    it 'the client first names should all include their PersonalIDs' do
      expect(GrdaWarehouse::Hud::Client.source.find_by(PersonalID: 'C-1').FirstName).to eq('First_C-1')
    end

    it 'the client last names should all include their PersonalIDs' do
      expect(GrdaWarehouse::Hud::Client.source.find_by(PersonalID: 'C-1').LastName).to eq('Last_C-1')
    end

    describe 'when importing updated enrollment data and de-identifying' do
      before(:all) do
        import_hmis_csv_fixture(
          'drivers/hmis_csv_twenty_twenty/spec/fixtures/files/allowed_projects',
          data_source: @data_source,
          version: '2020',
          deidentified: true,
          run_jobs: false,
        )
      end

      it 'it doesn\'t add additional clients' do
        expect(GrdaWarehouse::Hud::Client.source.count).to eq(3)
      end

      it 'the client first names should not include the word Client' do
        expect(GrdaWarehouse::Hud::Client.source.pluck(:FirstName).to_s).not_to include('Client')
      end
    end
  end # end describe enrollments
end
