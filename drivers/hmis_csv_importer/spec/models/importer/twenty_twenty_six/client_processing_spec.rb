###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisCsvImporter, type: :model do
  describe 'When importing clients' do
    before(:all) do
      HmisCsvImporter::Utility.clear!
      GrdaWarehouse::Utility.clear!
      import_hmis_csv_fixture(
        'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_six/client_processing',
        version: 'AutoMigrate',
        run_jobs: false,
        stop_version: '2026',
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
        @loader = import_hmis_csv_fixture(
          'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_six/client_processing',
          version: 'AutoMigrate',
          run_jobs: false,
          stop_version: '2026',
        )
      end

      it 'all clients have a non-nil source_hash' do
        expect(GrdaWarehouse::Hud::Client.source.pluck(:source_hash).compact.count).to eq(2)
      end

      it 'all enrollments have a non-nil source_hash' do
        expect(GrdaWarehouse::Hud::Enrollment.pluck(:source_hash).compact.count).to eq(4)
      end

      # Locks in mark_unchanged's NULL semantics: staging source_hash is non-NULL
      # by construction, so `staging.source_hash = wh.source_hash` never matches a
      # NULL warehouse row. Those rows must fall through to apply_updates.
      it 'marks zero clients as unchanged' do
        expect(@loader.importer_log.summary['Client.csv']['unchanged'].to_i).to eq(0)
      end

      describe 'when re-importing and the source hash doesn\'t match' do
        before(:all) do
          @loader = import_hmis_csv_fixture(
            'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_six/client_processing',
            version: 'AutoMigrate',
            run_jobs: false,
            stop_version: '2026',
          )
        end

        it 'all clients have a non-nil source_hash' do
          expect(GrdaWarehouse::Hud::Client.source.pluck(:source_hash).compact.count).to eq(2)
          expect(GrdaWarehouse::Hud::Client.source.where(source_hash: 'aaa').count).to eq(0)
        end

        # Complements the NULL case above: when staging and warehouse source_hashes
        # agree, mark_unchanged counts the row as unchanged (and clears the stale
        # pending_date_deleted flag without touching DateUpdated).
        it 'marks both clients as unchanged' do
          expect(@loader.importer_log.summary['Client.csv']['unchanged']).to eq(2)
        end

        it 'all enrollments have a non-nil source_hash' do
          expect(GrdaWarehouse::Hud::Enrollment.pluck(:source_hash).compact.count).to eq(4)
        end

        describe 'when re-importing with changed enrollment' do
          before(:all) do
            import_hmis_csv_fixture(
              'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_six/client_processing_2',
              version: 'AutoMigrate',
              run_jobs: false,
              stop_version: '2026',
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

    # Mixed case: one warehouse client has its source_hash nilled, the other is
    # left intact. Exercises the per-row nature of mark_unchanged's semi-join.
    describe 'when re-importing with only one client\'s source_hash nilled' do
      before(:all) do
        HmisCsvImporter::Utility.clear!
        GrdaWarehouse::Utility.clear!
        import_hmis_csv_fixture(
          'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_six/client_processing',
          version: 'AutoMigrate',
          run_jobs: false,
          stop_version: '2026',
        )
        GrdaWarehouse::Hud::Client.source.where(PersonalID: '1').update_all(source_hash: nil)
        @loader = import_hmis_csv_fixture(
          'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_six/client_processing',
          version: 'AutoMigrate',
          run_jobs: false,
          stop_version: '2026',
        )
      end

      it 'marks only the hash-matching client as unchanged' do
        expect(@loader.importer_log.summary['Client.csv']['unchanged']).to eq(1)
      end
    end
  end
end
