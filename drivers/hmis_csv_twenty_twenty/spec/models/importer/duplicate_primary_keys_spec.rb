###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe HmisCsvTwentyTwenty, type: :model do
  describe 'When importing data with duplicate primary keys' do
    before(:all) do
      HmisCsvTwentyTwenty::Utility.clear!
      GrdaWarehouse::Utility.clear!
      import_hmis_csv_fixture(
        'drivers/hmis_csv_twenty_twenty/spec/fixtures/files/duplicate_primary_keys',
        version: '2020',
        run_jobs: false,
      )
    end

    it 'the loader tables contain appropriate numbers of rows matching the CSVs' do
      aggregate_failures do
        expect(HmisCsvTwentyTwenty::Loader::Assessment.count).to eq(3)
        expect(HmisCsvTwentyTwenty::Loader::Client.count).to eq(5)
        expect(HmisCsvTwentyTwenty::Loader::Enrollment.count).to eq(5)
        expect(HmisCsvTwentyTwenty::Loader::Funder.count).to eq(3)
      end
    end

    it 'the importer tables contain appropriate numbers of rows matching the CSVs' do
      aggregate_failures do
        expect(HmisCsvTwentyTwenty::Importer::Assessment.count).to eq(3)
        expect(HmisCsvTwentyTwenty::Importer::Client.count).to eq(5)
        expect(HmisCsvTwentyTwenty::Importer::Enrollment.count).to eq(5)
        expect(HmisCsvTwentyTwenty::Importer::Funder.count).to eq(3)
      end
    end

    it 'the importer tables contain appropriate numbers of rows matching the CSVs which are ready to import' do
      aggregate_failures do
        expect(HmisCsvTwentyTwenty::Importer::Assessment.should_import.count).to eq(2)
        expect(HmisCsvTwentyTwenty::Importer::Client.should_import.count).to eq(3)
        expect(HmisCsvTwentyTwenty::Importer::Enrollment.should_import.count).to eq(4)
        expect(HmisCsvTwentyTwenty::Importer::Funder.should_import.count).to eq(1)
      end
    end

    it 'the warehouse tables contain appropriate numbers of rows' do
      aggregate_failures do
        expect(GrdaWarehouse::Hud::Assessment.count).to eq(2)
        expect(GrdaWarehouse::Hud::Client.source.count).to eq(3)
        expect(GrdaWarehouse::Hud::Enrollment.count).to eq(4)
        expect(GrdaWarehouse::Hud::Funder.count).to eq(1)
      end
    end

    it 'Appropriate error rows are generated' do
      expect(HmisCsvValidation::UniqueHudKey.count).to eq(6)
    end
  end
end
