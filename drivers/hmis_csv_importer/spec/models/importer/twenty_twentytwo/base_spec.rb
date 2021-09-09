###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe HmisCsvImporter, type: :model do
  describe 'When handling source files' do
    before(:all) do
      HmisCsvImporter::Utility.clear!
      GrdaWarehouse::Utility.clear!
    end

    it 'can import files with bom|UTF-8 encoding' do
      file_path = 'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twentytwo/bom_test'
      import_hmis_csv_fixture(file_path, version: 'AutoMigrate', run_jobs: false)
    end

    it 'can import files with bad line endings' do
      allow(Rails.logger).to receive(:debug).and_return nil
      # the files in this import have a incorrect (but seen in the wild) "\r\n" as
      # part of their final line while most lines end in "\n"
      file_path = 'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twentytwo/bad_ending'
      import_hmis_csv_fixture(file_path, version: 'AutoMigrate', run_jobs: false)

      # icky -- testing for side effects
      expect(Rails.logger).to have_received(:debug).with(/Correcting bad line ending.*Export.csv/)
      expect(Rails.logger).to have_received(:debug).with(/Correcting bad line ending.*Project.csv/)
    end
  end

  describe 'When importing enrollments' do
    before(:all) do
      HmisCsvImporter::Utility.clear!
      GrdaWarehouse::Utility.clear!
      import_hmis_csv_fixture(
        'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twentytwo/enrollment_test_files',
        version: 'AutoMigrate',
        run_jobs: true,
      )
    end

    it 'the database will have three source clients' do
      expect(GrdaWarehouse::Hud::Client.source.count).to eq(3)
    end

    it 'the database will have four enrollments' do
      expect(GrdaWarehouse::Hud::Enrollment.count).to eq(4)
    end

    it 'the database will have four service history enrollment entry records' do
      expect(GrdaWarehouse::ServiceHistoryEnrollment.entry.count).to eq(4)
    end

    it 'the database will have 18 services' do
      expect(GrdaWarehouse::Hud::Service.count).to eq(18)
    end

    it 'the database will have 17 service history service records' do
      expect(GrdaWarehouse::ServiceHistoryService.count).to eq(17)
    end

    it 'the effective export end date is 2017-09-20' do
      expect(GrdaWarehouse::Hud::Export.order(id: :asc).last.effective_export_end_date).to eq('2017-09-20'.to_date)
    end

    it 'the database will have two assessments' do
      expect(GrdaWarehouse::Hud::Assessment.count).to eq(2)
    end

    it 'the database will have four assessment questions' do
      expect(GrdaWarehouse::Hud::AssessmentQuestion.count).to eq(4)
    end

    it 'the database will have two assessment results' do
      expect(GrdaWarehouse::Hud::AssessmentResult.count).to eq(2)
    end

    it 'the database will have two events' do
      expect(GrdaWarehouse::Hud::Event.count).to eq(2)
    end

    it 'the database will have two living situations' do
      expect(GrdaWarehouse::Hud::CurrentLivingSituation.count).to eq(2)
    end

    it 'the database will have four users' do
      expect(GrdaWarehouse::Hud::User.count).to eq(4)
    end

    describe 'each client\'s counts will match expected counts' do
      clients = {
        '2f4b963171644a8b9902bdfe79a4b403' => {
          enrollments: 2,
          exits: 1,
          services: 16,
        },
        '4c9da990d51b4ed1a2e45b972aeaecee' => {
          enrollments: 1,
          exits: 0,
          services: 2,
        },
        '7b8c1279001142afac2fd0bde7a8f6bf' => {
          enrollments: 1,
          exits: 0,
          services: 0,
        },
      }

      clients.each do |personal_id, data|
        data.each do |association, count|
          it "#{personal_id} should have #{count} #{association}" do
            client = GrdaWarehouse::Hud::Client.where(PersonalID: personal_id).first
            expect(client.send(association).count).to eq(count)
          end
        end
      end
    end

    describe 'when importing updated enrollment data' do
      before(:all) do
        import_hmis_csv_fixture(
          'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twentytwo/enrollment_change_files',
          version: 'AutoMigrate',
          run_jobs: false,
        )
      end

      it 'it doesn\'t import enrollments that changed but have an earlier modification date' do
        expect(GrdaWarehouse::Hud::Enrollment.where(PersonalID: '2f4b963171644a8b9902bdfe79a4b403').pluck(:HouseholdID).reject(&:blank?)).to be_empty
      end

      it 'it imports enrollments that changed with an unchanged modification date' do
        expect(GrdaWarehouse::Hud::Enrollment.where(PersonalID: '4c9da990d51b4ed1a2e45b972aeaecee').pluck(:HouseholdID).reject(&:blank?)).to eq(['2222'])
      end

      it 'it imports enrollments that changed with a later modification date' do
        expect(GrdaWarehouse::Hud::Enrollment.where(PersonalID: '7b8c1279001142afac2fd0bde7a8f6bf').pluck(:HouseholdID).reject(&:blank?)).to eq(['3333'])
      end
    end
  end # end describe enrollments

  describe 'When importing enrollments with deletes' do
    before(:all) do
      HmisCsvImporter::Utility.clear!
      GrdaWarehouse::Utility.clear!
      import_hmis_csv_fixture(
        'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twentytwo/enrollment_with_deletes_test_files',
        version: 'AutoMigrate',
        run_jobs: false,
      )
    end

    it 'the database will have two clients' do
      expect(GrdaWarehouse::Hud::Client.source.count).to eq(2)
    end

    it 'the database will have two enrollments' do
      expect(GrdaWarehouse::Hud::Enrollment.count).to eq(2)
    end

    it 'the database will have 15 services' do
      expect(GrdaWarehouse::Hud::Service.count).to eq(15)
    end

    it 'the effective export end date is 2017-09-19' do
      expect(GrdaWarehouse::Hud::Export.order(id: :asc).last.effective_export_end_date).to eq('2017-09-19'.to_date)
    end

    it 'will clean up the pending deletes' do
      HmisCsvImporter::Importer::Importer.soft_deletable_sources.each do |source|
        expect(source.where.not(pending_date_deleted: nil).count).to eq 0
      end
    end

    describe 'each client\'s counts will match expected counts' do
      clients = {
        '2f4b963171644a8b9902bdfe79a4b403' => {
          enrollments: 1,
          exits: 1,
          services: 0,
        },
        '7b8c1279001142afac2fd0bde7a8f6bf' => {
          enrollments: 1,
          exits: 0,
          services: 0,
        },
      }

      clients.each do |personal_id, data|
        data.each do |association, count|
          it "#{personal_id} should have #{count} #{association}" do
            client = GrdaWarehouse::Hud::Client.where(PersonalID: personal_id).first
            expect(client.send(association).count).to eq(count)
          end
        end
      end
    end

    describe 'client counts with deleted items will match expected counts' do
      clients = {
        '2f4b963171644a8b9902bdfe79a4b403' => {
          enrollments: 2,
          exits: 1,
          services: 16,
        },
        '4c9da990d51b4ed1a2e45b972aeaecee' => {
          enrollments: 1,
          exits: 0,
          services: 2,
        },
        '7b8c1279001142afac2fd0bde7a8f6bf' => {
          enrollments: 1,
          exits: 0,
          services: 0,
        },
      }

      clients.each do |personal_id, data|
        data.each do |association, count|
          it "#{personal_id} should have #{count} #{association}" do
            client = GrdaWarehouse::Hud::Client.with_deleted.where(PersonalID: personal_id).first
            expect(client.send(association).with_deleted.count).to eq(count)
          end
        end
      end
    end
  end # End describe enrollments with deleted

  describe 'When importing projects' do
    before(:all) do
      HmisCsvImporter::Utility.clear!
      GrdaWarehouse::Utility.clear!
      import_hmis_csv_fixture(
        'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twentytwo/project_test_files',
        version: 'AutoMigrate',
        run_jobs: false,
      )
    end

    it 'the database will have five projects' do
      expect(GrdaWarehouse::Hud::Project.count).to eq(5)
    end

    it 'the database will have five projects cocs' do
      expect(GrdaWarehouse::Hud::ProjectCoc.count).to eq(5)
    end

    it 'the database will have four organizations' do
      expect(GrdaWarehouse::Hud::Organization.count).to eq(4)
    end

    it 'the database will have four inventories' do
      expect(GrdaWarehouse::Hud::Inventory.count).to eq(4)
    end

    it 'the database will have five funders' do
      expect(GrdaWarehouse::Hud::Funder.count).to eq(5)
    end

    it 'organization 108 has two projects' do
      expect(GrdaWarehouse::Hud::Organization.where(OrganizationID: 108).first.projects.count).to eq(2)
    end

    describe 'projects have appropriate relations' do
      projects = {
        469 => {
          funders: 1,
          project_cocs: 1,
          inventories: 2,
        },
        506 => {
          funders: 1,
          project_cocs: 1,
          inventories: 0,
        },
      }

      projects.each do |project_id, data|
        data.each do |association, count|
          it "#{project_id} should have #{count} #{association}" do
            project = GrdaWarehouse::Hud::Project.where(ProjectID: project_id).first
            expect(project.send(association).count).to eq(count)
          end
        end
      end
    end
  end # End describe projects

  describe 'When importing enrollments and clients with restores' do
    before(:all) do
      HmisCsvImporter::Utility.clear!
      GrdaWarehouse::Utility.clear!

      import_hmis_csv_fixture(
        'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twentytwo/enrollment_test_with_restores_initial_files',
        version: 'AutoMigrate',
        run_jobs: false,
      )
    end

    it 'has no enrollments' do
      expect(GrdaWarehouse::Hud::Enrollment.count).to eq(0)
    end

    it 'has one deleted enrollments' do
      expect(GrdaWarehouse::Hud::Enrollment.only_deleted.count).to eq(1)
    end

    it 'has no clients' do
      expect(GrdaWarehouse::Hud::Client.count).to eq(0)
    end

    it 'has one deleted clients' do
      expect(GrdaWarehouse::Hud::Client.only_deleted.count).to eq(1)
    end

    it 'import log summary counts are as expected' do
      log = HmisCsvImporter::Importer::ImporterLog.last
      aggregate_failures 'checking enrollment counts' do
        expect(log.summary['Enrollment.csv']['added']).to eq(1)
        expect(log.summary['Enrollment.csv']['updated']).to eq(0)
        expect(log.summary['Enrollment.csv']['unchanged']).to eq(0)
      end

      aggregate_failures 'checking client counts' do
        expect(log.summary['Client.csv']['added']).to eq(1)
        expect(log.summary['Client.csv']['updated']).to eq(0)
        expect(log.summary['Client.csv']['unchanged']).to eq(0)
      end
    end

    describe 'after second import' do
      before(:all) do
        import_hmis_csv_fixture(
          'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twentytwo/enrollment_test_with_restores_update_files',
          version: 'AutoMigrate',
          run_jobs: false,
        )
      end

      it 'has two enrollments' do
        expect(GrdaWarehouse::Hud::Enrollment.count).to eq(2)
      end

      it 'has no deleted enrollments' do
        expect(GrdaWarehouse::Hud::Enrollment.only_deleted.count).to eq(0)
      end

      it 'has two clients' do
        expect(GrdaWarehouse::Hud::Client.source.count).to eq(2)
      end

      it 'has no deleted clients' do
        expect(GrdaWarehouse::Hud::Client.only_deleted.count).to eq(0)
      end

      it 'import log summary counts are as expected' do
        log = HmisCsvImporter::Importer::ImporterLog.last
        aggregate_failures 'checking enrollment counts' do
          expect(log.summary['Enrollment.csv']['added']).to eq(1)
          expect(log.summary['Enrollment.csv']['updated']).to eq(1)
          expect(log.summary['Enrollment.csv']['unchanged']).to eq(0)
        end

        aggregate_failures 'checking client counts' do
          expect(log.summary['Client.csv']['added']).to eq(1)
          expect(log.summary['Client.csv']['updated']).to eq(1)
          expect(log.summary['Client.csv']['unchanged']).to eq(0)
        end
      end
    end
  end
end
