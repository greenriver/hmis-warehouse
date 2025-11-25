###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Custom Augmentation File Imports', type: :model do
  def cleanup_import_state
    GrdaWarehouse::Utility.clear!
    HmisCsvImporter::Utility.clear!
  end

  describe 'When importing custom enrollment augmentation data using factory' do
    context 'baseline import without augmentation' do
      before(:all) do
        @factory = HmisCsvFixtureFactory.new
        @factory.export_start_date = Date.new(2024, 1, 1)
        @factory.export_end_date = Date.new(2024, 3, 31)

        @factory.add_client(personal_id: 'client-1', first_name: 'Test', last_name: 'One')
        @factory.add_client(personal_id: 'client-2', first_name: 'Test', last_name: 'Two')
        @factory.add_client(personal_id: 'client-3', first_name: 'Test', last_name: 'Three')

        @factory.add_enrollment(enrollment_id: 'enroll-1', personal_id: 'client-1', entry_date: Date.new(2024, 1, 15))
        @factory.add_enrollment(enrollment_id: 'enroll-2', personal_id: 'client-2', entry_date: Date.new(2024, 2, 1))
        @factory.add_enrollment(enrollment_id: 'enroll-3', personal_id: 'client-3', entry_date: Date.new(2024, 2, 15))

        path = @factory.create!
        import_hmis_csv_fixture(path, run_jobs: false)
      end

      after(:all) do
        @factory&.cleanup!
        cleanup_import_state
      end

      it 'imports enrollments' do
        expect(GrdaWarehouse::Hud::Enrollment.count).to eq(3)
      end

      it 'enrollments do not have custom augmentation fields set' do
        enrollments = GrdaWarehouse::Hud::Enrollment.all
        expect(enrollments.pluck(:SexualOrientation).compact).to be_empty
        expect(enrollments.pluck(:TranslationNeeded).compact).to be_empty
      end
    end

    context 'with custom enrollment augmentation' do
      before(:all) do
        @factory = HmisCsvFixtureFactory.new
        @factory.export_start_date = Date.new(2024, 1, 1)
        @factory.export_end_date = Date.new(2024, 3, 31)

        @factory.add_client(personal_id: 'client-1', first_name: 'Test', last_name: 'One')
        @factory.add_client(personal_id: 'client-2', first_name: 'Test', last_name: 'Two')
        @factory.add_client(personal_id: 'client-3', first_name: 'Test', last_name: 'Three')

        @factory.add_enrollment(enrollment_id: 'enroll-1', personal_id: 'client-1', entry_date: Date.new(2024, 1, 15))
        @factory.add_enrollment(enrollment_id: 'enroll-2', personal_id: 'client-2', entry_date: Date.new(2024, 2, 1))
        @factory.add_enrollment(enrollment_id: 'enroll-3', personal_id: 'client-3', entry_date: Date.new(2024, 2, 15))

        @factory.add_custom_enrollment_augmentation(enrollment_id: 'enroll-1', personal_id: 'client-1', sexual_orientation: 1, translation_needed: 0)
        @factory.add_custom_enrollment_augmentation(enrollment_id: 'enroll-2', personal_id: 'client-2', sexual_orientation: 2, translation_needed: 1, preferred_language: 2)

        path = @factory.create!
        import_hmis_csv_fixture(path, run_jobs: false)
      end

      after(:all) do
        @factory&.cleanup!
        cleanup_import_state
      end

      it 'still has the same number of enrollments' do
        expect(GrdaWarehouse::Hud::Enrollment.count).to eq(3)
      end

      it 'augmented enrollments have custom fields populated' do
        enrollment_1 = GrdaWarehouse::Hud::Enrollment.find_by(EnrollmentID: 'enroll-1')
        expect(enrollment_1.SexualOrientation).to eq(1)
        expect(enrollment_1.TranslationNeeded).to eq(0)

        enrollment_2 = GrdaWarehouse::Hud::Enrollment.find_by(EnrollmentID: 'enroll-2')
        expect(enrollment_2.SexualOrientation).to eq(2)
        expect(enrollment_2.TranslationNeeded).to eq(1)
        expect(enrollment_2.PreferredLanguage).to eq(2)
      end

      it 'non-augmented enrollment remains unchanged' do
        enrollment_3 = GrdaWarehouse::Hud::Enrollment.find_by(EnrollmentID: 'enroll-3')
        expect(enrollment_3.SexualOrientation).to be_nil
        expect(enrollment_3.TranslationNeeded).to be_nil
      end

      it 'import log summary shows correct counts' do
        log = HmisCsvImporter::Importer::ImporterLog.last
        aggregate_failures 'checking custom file counts' do
          expect(log.summary['CustomEnrollmentFY26Deprecations.csv']['added']).to eq(0)
          expect(log.summary['CustomEnrollmentFY26Deprecations.csv']['updated']).to eq(2)
          expect(log.summary['CustomEnrollmentFY26Deprecations.csv']['removed']).to eq(0)
        end
      end
    end

    context 'with custom gender augmentation' do
      before(:all) do
        @factory = HmisCsvFixtureFactory.new
        @factory.export_start_date = Date.new(2024, 1, 1)
        @factory.export_end_date = Date.new(2024, 3, 31)

        @factory.add_client(personal_id: 'client-1', first_name: 'Test', last_name: 'One')
        @factory.add_client(personal_id: 'client-2', first_name: 'Test', last_name: 'Two')
        @factory.add_client(personal_id: 'client-3', first_name: 'Test', last_name: 'Three')

        @factory.add_enrollment(enrollment_id: 'enroll-1', personal_id: 'client-1', entry_date: Date.new(2024, 1, 15))
        @factory.add_enrollment(enrollment_id: 'enroll-2', personal_id: 'client-2', entry_date: Date.new(2024, 2, 1))
        @factory.add_enrollment(enrollment_id: 'enroll-3', personal_id: 'client-3', entry_date: Date.new(2024, 2, 15))

        @factory.add_custom_gender_augmentation(personal_id: 'client-1', woman: 1, non_binary: 0)
        @factory.add_custom_gender_augmentation(personal_id: 'client-2', woman: 0, non_binary: 1)

        path = @factory.create!
        import_hmis_csv_fixture(path, run_jobs: false)
      end

      after(:all) do
        @factory&.cleanup!
        cleanup_import_state
      end

      it 'still has the same number of clients' do
        expect(GrdaWarehouse::Hud::Client.source.count).to eq(3)
      end

      it 'augmented clients have custom gender fields populated' do
        client_1 = GrdaWarehouse::Hud::Client.source.find_by(PersonalID: 'client-1')
        expect(client_1.Woman).to eq(1)
        expect(client_1.NonBinary).to eq(0)

        client_2 = GrdaWarehouse::Hud::Client.source.find_by(PersonalID: 'client-2')
        expect(client_2.Woman).to eq(0)
        expect(client_2.NonBinary).to eq(1)
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

  describe 'Large dataset augmentation using factory' do
    before(:all) do
      @factory = HmisCsvFixtureFactory.new
      @factory.export_start_date = Date.new(2024, 1, 1)
      @factory.export_end_date = Date.new(2024, 3, 31)

      # Generate 150 clients and enrollments
      150.times do |i|
        client_id = "client-large-#{i + 1}"
        enrollment_id = "enroll-large-#{i + 1}"
        @factory.add_client(personal_id: client_id, first_name: 'Large', last_name: "Test#{i + 1}")
        @factory.add_enrollment(enrollment_id: enrollment_id, personal_id: client_id, entry_date: Date.new(2024, 1, 5))
        @factory.add_custom_enrollment_augmentation(
          enrollment_id: enrollment_id,
          personal_id: client_id,
          sexual_orientation: (i % 5) + 1,
          translation_needed: i.even? ? 0 : 1,
        )
      end

      path = @factory.create!
      import_hmis_csv_fixture(path, run_jobs: false)
    end

    after(:all) do
      @factory&.cleanup!
      cleanup_import_state
    end

    it 'imports many enrollments successfully' do
      expect(GrdaWarehouse::Hud::Enrollment.count).to be >= 100
    end

    it 'successfully augments all enrollments' do
      augmented_count = GrdaWarehouse::Hud::Enrollment.where.not(SexualOrientation: nil).count
      expect(augmented_count).to be >= 100
    end

    it 'import log shows correct pre_processed and updated counts' do
      log = HmisCsvImporter::Importer::ImporterLog.last
      summary = log.summary['CustomEnrollmentFY26Deprecations.csv']
      expect(summary['pre_processed']).to be >= 100
      expect(summary['updated']).to be >= 100
    end

    it 'import completes successfully' do
      log = HmisCsvImporter::Importer::ImporterLog.last
      expect(log.status).to eq('complete')
    end
  end

  describe 'Augmentation files never delete records using factory' do
    before(:all) do
      # Baseline import
      @baseline_factory = HmisCsvFixtureFactory.new
      @baseline_factory.export_start_date = Date.new(2024, 1, 1)
      @baseline_factory.export_end_date = Date.new(2024, 3, 31)

      @baseline_factory.add_client(personal_id: 'client-1', first_name: 'Test', last_name: 'One')
      @baseline_factory.add_client(personal_id: 'client-2', first_name: 'Test', last_name: 'Two')
      @baseline_factory.add_client(personal_id: 'client-3', first_name: 'Test', last_name: 'Three')

      @baseline_factory.add_enrollment(enrollment_id: 'enroll-1', personal_id: 'client-1', entry_date: Date.new(2024, 1, 15))
      @baseline_factory.add_enrollment(enrollment_id: 'enroll-2', personal_id: 'client-2', entry_date: Date.new(2024, 2, 1))
      @baseline_factory.add_enrollment(enrollment_id: 'enroll-3', personal_id: 'client-3', entry_date: Date.new(2024, 2, 15))

      baseline_path = @baseline_factory.create!
      import_hmis_csv_fixture(baseline_path, run_jobs: false)

      # Full augmentation import
      @augmentation_factory = HmisCsvFixtureFactory.new
      @augmentation_factory.export_id = @baseline_factory.export_id
      @augmentation_factory.export_start_date = Date.new(2024, 1, 1)
      @augmentation_factory.export_end_date = Date.new(2024, 3, 31)

      @augmentation_factory.add_client(personal_id: 'client-1', first_name: 'Test', last_name: 'One')
      @augmentation_factory.add_client(personal_id: 'client-2', first_name: 'Test', last_name: 'Two')
      @augmentation_factory.add_client(personal_id: 'client-3', first_name: 'Test', last_name: 'Three')

      @augmentation_factory.add_enrollment(enrollment_id: 'enroll-1', personal_id: 'client-1', entry_date: Date.new(2024, 1, 15))
      @augmentation_factory.add_enrollment(enrollment_id: 'enroll-2', personal_id: 'client-2', entry_date: Date.new(2024, 2, 1))
      @augmentation_factory.add_enrollment(enrollment_id: 'enroll-3', personal_id: 'client-3', entry_date: Date.new(2024, 2, 15))

      @augmentation_factory.add_custom_enrollment_augmentation(enrollment_id: 'enroll-1', personal_id: 'client-1', sexual_orientation: 1, translation_needed: 0)
      @augmentation_factory.add_custom_enrollment_augmentation(enrollment_id: 'enroll-2', personal_id: 'client-2', sexual_orientation: 2, translation_needed: 1)

      augmentation_path = @augmentation_factory.create!
      import_hmis_csv_fixture(augmentation_path, run_jobs: false)

      # Partial augmentation - only one enrollment, with different value
      @partial_factory = HmisCsvFixtureFactory.new
      @partial_factory.export_id = @baseline_factory.export_id
      @partial_factory.export_start_date = Date.new(2024, 1, 1)
      @partial_factory.export_end_date = Date.new(2024, 3, 31)

      @partial_factory.add_client(personal_id: 'client-1', first_name: 'Test', last_name: 'One')
      @partial_factory.add_client(personal_id: 'client-2', first_name: 'Test', last_name: 'Two')
      @partial_factory.add_client(personal_id: 'client-3', first_name: 'Test', last_name: 'Three')

      @partial_factory.add_enrollment(enrollment_id: 'enroll-1', personal_id: 'client-1', entry_date: Date.new(2024, 1, 15))
      @partial_factory.add_enrollment(enrollment_id: 'enroll-2', personal_id: 'client-2', entry_date: Date.new(2024, 2, 1))
      @partial_factory.add_enrollment(enrollment_id: 'enroll-3', personal_id: 'client-3', entry_date: Date.new(2024, 2, 15))

      # Only augment enroll-1 with a new value
      @partial_factory.add_custom_enrollment_augmentation(enrollment_id: 'enroll-1', personal_id: 'client-1', sexual_orientation: 5)

      partial_path = @partial_factory.create!
      import_hmis_csv_fixture(partial_path, run_jobs: false)
    end

    after(:all) do
      @baseline_factory&.cleanup!
      @augmentation_factory&.cleanup!
      @partial_factory&.cleanup!
      cleanup_import_state
    end

    it 'has augmented enrollments' do
      expect(GrdaWarehouse::Hud::Enrollment.where.not(SexualOrientation: nil).count).to eq(2)
    end

    it 'does not remove augmentation data from records not in the file' do
      enrollment_2 = GrdaWarehouse::Hud::Enrollment.find_by(EnrollmentID: 'enroll-2')
      expect(enrollment_2.SexualOrientation).to eq(2)
      expect(enrollment_2.TranslationNeeded).to eq(1)
    end

    it 'updates the enrollment that is in the file' do
      enrollment_1 = GrdaWarehouse::Hud::Enrollment.find_by(EnrollmentID: 'enroll-1')
      expect(enrollment_1.SexualOrientation).to eq(5)
    end

    it 'does not delete any enrollments' do
      expect(GrdaWarehouse::Hud::Enrollment.count).to eq(3)
      expect(GrdaWarehouse::Hud::Enrollment.only_deleted.count).to eq(0)
    end
  end
end
