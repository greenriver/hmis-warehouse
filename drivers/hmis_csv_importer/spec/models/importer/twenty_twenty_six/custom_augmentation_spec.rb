###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'csv'

require 'rails_helper'

RSpec.describe 'Custom Augmentation File Imports', type: :model do
  FIXTURE_BASE_PATH = Rails.root.join(
    'drivers',
    'hmis_csv_importer',
    'spec',
    'fixtures',
    'files',
    'twenty_twenty_six',
    'custom_augmentation_test',
  ).freeze

  def import_custom_augmentation_fixture(folder)
    import_hmis_csv_fixture(
      "drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_six/custom_augmentation_test/#{folder}",
      run_jobs: false,
    )
  end

  def cleanup_import_state
    GrdaWarehouse::Utility.clear!
    HmisCsvImporter::Utility.clear!
  end

  def ensure_enrollment_dates_within_export_window!(folder)
    source_path = FIXTURE_BASE_PATH.join(folder, 'source')
    export_row = CSV.read(source_path.join('Export.csv'), headers: true).first
    raise "Export.csv missing for #{folder}" unless export_row

    start_date = Date.parse(export_row['ExportStartDate'])
    end_date = Date.parse(export_row['ExportEndDate'])
    enrollment_csv = source_path.join('Enrollment.csv')

    CSV.foreach(enrollment_csv, headers: true) do |row|
      next if row['EntryDate'].blank?

      entry_date = Date.parse(row['EntryDate'])
      next if entry_date.between?(start_date, end_date)

      raise(
        "Enrollment #{row['EnrollmentID']} in #{folder} has EntryDate #{entry_date} outside export window #{start_date}..#{end_date}",
      )
    end
  end

  describe 'When importing custom enrollment augmentation data' do
    context 'with only the baseline import' do
      before(:all) do
        import_custom_augmentation_fixture('baseline')
      end

      after(:all) { cleanup_import_state }

      it 'baseline enrollments are imported' do
        expect(GrdaWarehouse::Hud::Enrollment.count).to eq(4)
      end

      it 'baseline enrollments do not have custom augmentation fields set' do
        enrollments = GrdaWarehouse::Hud::Enrollment.all
        expect(enrollments.pluck(:SexualOrientation).compact).to be_empty
        expect(enrollments.pluck(:TranslationNeeded).compact).to be_empty
      end
    end

    describe 'after importing custom augmentation file' do
      before(:all) do
        import_custom_augmentation_fixture('baseline')
        import_custom_augmentation_fixture('with_custom')
      end

      after(:all) { cleanup_import_state }

      it 'still has the same number of enrollments' do
        expect(GrdaWarehouse::Hud::Enrollment.count).to eq(4)
      end

      it 'augmented enrollments have custom fields populated' do
        # Enrollment 557331 should have SexualOrientation and TranslationNeeded set
        enrollment_1 = GrdaWarehouse::Hud::Enrollment.find_by(EnrollmentID: '557331')
        expect(enrollment_1.SexualOrientation).to eq(1) # Heterosexual
        expect(enrollment_1.TranslationNeeded).to eq(0) # No

        # Enrollment 557890 should have different values
        enrollment_2 = GrdaWarehouse::Hud::Enrollment.find_by(EnrollmentID: '557890')
        expect(enrollment_2.SexualOrientation).to eq(2) # Gay
        expect(enrollment_2.TranslationNeeded).to eq(1) # Yes
        expect(enrollment_2.PreferredLanguage).to eq(2) # Spanish
      end

      it 'non-augmented enrollment remains unchanged' do
        # Enrollment 559123 was not in the custom file, so should remain nil
        enrollment_3 = GrdaWarehouse::Hud::Enrollment.find_by(EnrollmentID: '559123')
        expect(enrollment_3.SexualOrientation).to be_nil
        expect(enrollment_3.TranslationNeeded).to be_nil
      end

      it 'import log summary shows correct counts' do
        log = HmisCsvImporter::Importer::ImporterLog.last
        aggregate_failures 'checking custom file counts' do
          # Custom augmentation files should only update, never add or remove
          expect(log.summary['CustomEnrollmentFY26Deprecations.csv']['added']).to eq(0)
          expect(log.summary['CustomEnrollmentFY26Deprecations.csv']['updated']).to eq(2)
          expect(log.summary['CustomEnrollmentFY26Deprecations.csv']['removed']).to eq(0)
        end
      end
    end

    describe 'after updating custom augmentation data' do
      before(:all) do
        import_custom_augmentation_fixture('baseline')
        import_custom_augmentation_fixture('updated_custom')
      end

      after(:all) { cleanup_import_state }

      it 'updates existing augmented fields' do
        enrollment_1 = GrdaWarehouse::Hud::Enrollment.find_by(EnrollmentID: '557331')
        # SexualOrientation changed from 1 to 3
        expect(enrollment_1.SexualOrientation).to eq(3) # Bisexual
        expect(enrollment_1.TranslationNeeded).to eq(0) # Still No
      end

      it 'can augment previously non-augmented enrollments' do
        # Enrollment 559123 now gets augmented
        enrollment_3 = GrdaWarehouse::Hud::Enrollment.find_by(EnrollmentID: '559123')
        expect(enrollment_3.SexualOrientation).to eq(4) # Questioning
        expect(enrollment_3.TranslationNeeded).to eq(1) # Yes
      end
    end
  end

  describe 'When importing custom client augmentation data' do
    context 'with only the baseline import' do
      before(:all) do
        import_custom_augmentation_fixture('baseline')
      end

      after(:all) { cleanup_import_state }

      it 'baseline clients are imported' do
        expect(GrdaWarehouse::Hud::Client.source.count).to eq(3)
      end

      it 'baseline clients do not have custom gender fields set' do
        clients = GrdaWarehouse::Hud::Client.source.all
        expect(clients.pluck(:Woman).compact).to be_empty
        expect(clients.pluck(:NonBinary).compact).to be_empty
      end
    end

    describe 'after importing custom gender augmentation file' do
      before(:all) do
        import_custom_augmentation_fixture('baseline')
        import_custom_augmentation_fixture('with_custom_gender')
      end

      after(:all) { cleanup_import_state }

      it 'still has the same number of clients' do
        expect(GrdaWarehouse::Hud::Client.source.count).to eq(3)
      end

      it 'augmented clients have custom gender fields populated' do
        client_1 = GrdaWarehouse::Hud::Client.source.find_by(PersonalID: '2f4b963171644a8b9902bdfe79a4b403')
        expect(client_1.Woman).to eq(1) # Yes
        expect(client_1.NonBinary).to eq(0) # No

        client_2 = GrdaWarehouse::Hud::Client.source.find_by(PersonalID: '4c9da990d51b4ed1a2e45b972aeaecee')
        expect(client_2.NonBinary).to eq(1) # Yes
        expect(client_2.Woman).to eq(0) # No
      end

      it 'import log summary shows correct counts' do
        log = HmisCsvImporter::Importer::ImporterLog.last
        aggregate_failures 'checking custom gender file counts' do
          expect(log.summary['CustomGender.csv']['added']).to eq(0)
          expect(log.summary['CustomGender.csv']['updated']).to eq(2)
          expect(log.summary['CustomGender.csv']['removed']).to eq(0)
        end
      end
    end
  end

  describe 'When importing large custom augmentation datasets' do
    before(:all) do
      ensure_enrollment_dates_within_export_window!('large_baseline')
      ensure_enrollment_dates_within_export_window!('large_custom')

      import_custom_augmentation_fixture('large_baseline')
      import_custom_augmentation_fixture('large_custom')
    end

    after(:all) { cleanup_import_state }

    it 'imports many enrollments successfully' do
      # This test ensures we have enough data to trigger batch processing
      expect(GrdaWarehouse::Hud::Enrollment.count).to be >= 100
    end

    it 'successfully augments all enrollments without memory issues' do
      # Verify that batch processing worked correctly
      augmented_count = GrdaWarehouse::Hud::Enrollment.where.not(SexualOrientation: nil).count
      expect(augmented_count).to be >= 100
    end

    it 'imports augmentation rows within the export window' do
      log = HmisCsvImporter::Importer::ImporterLog.last
      summary = log.summary['CustomEnrollmentFY26Deprecations.csv']
      expect(summary['pre_processed']).to be >= 100
      expect(summary['updated']).to be >= 100
    end

    it 'import completes successfully' do
      log = HmisCsvImporter::Importer::ImporterLog.last
      expect(log.status).to eq('complete')
    end

    it 'processes records in batches as evidenced by update count' do
      log = HmisCsvImporter::Importer::ImporterLog.last
      updated_count = log.summary['CustomEnrollmentFY26Deprecations.csv']['updated']
      # Should have updated at least 100 records
      expect(updated_count).to be >= 100
    end
  end

  describe 'Custom augmentation files never delete records' do
    before(:all) do
      import_custom_augmentation_fixture('baseline')
      import_custom_augmentation_fixture('with_custom')
    end

    after(:all) { cleanup_import_state }

    it 'has augmented enrollments' do
      expect(GrdaWarehouse::Hud::Enrollment.where.not(SexualOrientation: nil).count).to eq(2)
    end

    describe 'after importing custom file with fewer records' do
      before(:all) do
        import_custom_augmentation_fixture('partial_custom')
      end

      after(:all) { cleanup_import_state }

      it 'does not remove augmentation data from records not in the file' do
        # Enrollment 557890 was augmented before but is not in the partial_custom file
        # Its augmentation data should remain intact
        enrollment_2 = GrdaWarehouse::Hud::Enrollment.find_by(EnrollmentID: '557890')
        expect(enrollment_2.SexualOrientation).to eq(2) # Still has the value
        expect(enrollment_2.TranslationNeeded).to eq(1) # Still has the value
      end

      it 'updates the enrollment that is in the file' do
        enrollment_1 = GrdaWarehouse::Hud::Enrollment.find_by(EnrollmentID: '557331')
        # This one is in the partial file with updated values
        expect(enrollment_1.SexualOrientation).to eq(5) # Different value
      end

      it 'does not delete any enrollments' do
        expect(GrdaWarehouse::Hud::Enrollment.count).to eq(4)
        expect(GrdaWarehouse::Hud::Enrollment.only_deleted.count).to eq(0)
      end
    end
  end
end
