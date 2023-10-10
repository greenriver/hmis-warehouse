###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe HmisCsvImporter, type: :model do
  describe 'When importing clients' do
    before(:all) do
      HmisCsvImporter::Utility.clear!
      GrdaWarehouse::Utility.clear!
      import_hmis_csv_fixture(
        'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_four/client_processing',
        version: 'AutoMigrate',
        run_jobs: false,
      )
    end

    it 'the database will have the expected number of source clients' do
      expect(GrdaWarehouse::Hud::Client.source.count).to eq(2)
    end

    it 'the database will have the expected number of enrollments' do
      expect(GrdaWarehouse::Hud::Enrollment.count).to eq(4)
    end

    it 'all clients have a non-nil source_hash' do
      expect(GrdaWarehouse::Hud::Client.source.pluck(:source_hash).compact.count).to eq(2)
    end

    it 'all enrollments have a non-nil source_hash' do
      expect(GrdaWarehouse::Hud::Enrollment.pluck(:source_hash).compact.count).to eq(4)
    end

    describe 'when re-importing again after nulling source_hash' do
      before(:all) do
        # Force an update
        GrdaWarehouse::Hud::Client.source.update(source_hash: nil)
        import_hmis_csv_fixture(
          'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_four/client_processing',
          version: 'AutoMigrate',
          run_jobs: false,
        )
      end

      it 'all clients have a non-nil source_hash' do
        expect(GrdaWarehouse::Hud::Client.source.pluck(:source_hash).compact.count).to eq(2)
      end

      it 'all enrollments have a non-nil source_hash' do
        expect(GrdaWarehouse::Hud::Enrollment.pluck(:source_hash).compact.count).to eq(4)
      end

      describe 'when re-importing and the source hash doesn\'t match' do
        before(:all) do
          import_hmis_csv_fixture(
            'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_four/client_processing',
            version: 'AutoMigrate',
            run_jobs: false,
          )
        end

        it 'all clients have a non-nil source_hash' do
          expect(GrdaWarehouse::Hud::Client.source.pluck(:source_hash).compact.count).to eq(2)
          expect(GrdaWarehouse::Hud::Client.source.where(source_hash: 'aaa').count).to eq(0)
        end

        it 'all enrollments have a non-nil source_hash' do
          expect(GrdaWarehouse::Hud::Enrollment.pluck(:source_hash).compact.count).to eq(4)
        end

        describe 'when re-importing with changed enrollment' do
          before(:all) do
            import_hmis_csv_fixture(
              'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_four/client_processing_2',
              version: 'AutoMigrate',
              run_jobs: false,
            )
          end

          it 'all clients have a non-nil source_hash' do
            expect(GrdaWarehouse::Hud::Client.source.pluck(:source_hash).compact.count).to eq(2)
          end

          it 'all enrollments have a non-nil source_hash' do
            expect(GrdaWarehouse::Hud::Enrollment.pluck(:source_hash).compact.count).to eq(4)
          end
        end
      end
    end
  end
end
