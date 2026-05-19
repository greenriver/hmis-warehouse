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

      # NULL warehouse rows fall through to apply_updates and are not marked unchanged
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

        # When staging and warehouse hashes agree, rows are marked unchanged
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

    # incoming_older_processing is identical to client_processing except:
    #   Export.csv  — ExportDate set to 2018-01-01 (older than the 2021-05-25 established by
    #                 the first import), so most_recent_export_for_ds? returns false and
    #                 mark_incoming_older is not skipped.
    #   Client.csv  — Client 1 DateUpdated set to 2015-01-01 (older than the warehouse value
    #                 of 2018-12-02), Client 2 DateUpdated unchanged (equal, not strictly older).
    describe 'when the incoming record has an older DateUpdated than the warehouse' do
      before(:all) do
        HmisCsvImporter::Utility.clear!
        GrdaWarehouse::Utility.clear!
        import_hmis_csv_fixture(
          'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_six/client_processing',
          version: 'AutoMigrate',
          run_jobs: false,
          stop_version: '2026',
        )
        # Null both source_hashes so mark_unchanged (hash equality check) skips both clients
        # and only mark_incoming_older can contribute to the unchanged count.
        GrdaWarehouse::Hud::Client.source.update_all(source_hash: nil)
        @loader = import_hmis_csv_fixture(
          'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_six/incoming_older_processing',
          version: 'AutoMigrate',
          run_jobs: false,
          stop_version: '2026',
        )
      end

      # Client 1: incoming DateUpdated (2015-01-01) < warehouse DateUpdated (2018-12-02) → marked by mark_incoming_older
      # Client 2: incoming DateUpdated (2021-05-15) == warehouse DateUpdated (2021-05-15) → not strictly older, not marked
      it 'marks only the client with the older incoming DateUpdated as unchanged' do
        expect(@loader.importer_log.summary['Client.csv']['unchanged']).to eq(1)
      end
    end

    # Exercises the bulk upsert path in apply_updates for an enrollment-child model
    # (Disability uses DisabilitiesID as hud_key, not PersonalID, so it takes the
    # process_batch! branch rather than the Client one-by-one branch).
    describe 'when re-importing disabilities after nulling source_hash' do
      before(:all) do
        HmisCsvImporter::Utility.clear!
        GrdaWarehouse::Utility.clear!
        import_hmis_csv_fixture(
          'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_six/client_processing',
          version: 'AutoMigrate',
          run_jobs: false,
          stop_version: '2026',
        )
        GrdaWarehouse::Hud::Disability.update_all(source_hash: nil)
        @loader = import_hmis_csv_fixture(
          'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_six/client_processing',
          version: 'AutoMigrate',
          run_jobs: false,
          stop_version: '2026',
        )
      end

      it 'updates all disability records via apply_updates' do
        expect(@loader.importer_log.summary['Disabilities.csv']['updated']).to eq(12)
      end

      it 'repopulates source_hash on all disability records' do
        expect(GrdaWarehouse::Hud::Disability.where.not(source_hash: nil).count).to eq(12)
      end

      it 'preserves disability column values from the CSV' do
        disability = GrdaWarehouse::Hud::Disability.find_by(DisabilitiesID: '2')
        expect(disability.DisabilityType).to eq(6)
        expect(disability.DisabilityResponse).to eq(1)
      end
    end

    # Mixed case: only one warehouse client has its source_hash nilled
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
