require 'rails_helper'

RSpec.describe Importers::HmisTwentyTwenty::Base, type: :model do
  describe 'When importing enrollments' do
    before(:all) do
      GrdaWarehouse::Utility.clear!
      import_hmis_csv_fixture(
        'spec/fixtures/files/importers/hmis_twenty_twenty/enrollment_test_files',
        version: '2020',
        run_jobs: false,
      )
    end
    after(:all) do
      # Because we are only running the import once, we have to do our own DB and file cleanup
      GrdaWarehouse::Utility.clear!
      cleanup_hmis_csv_fixtures
    end
    it 'the database will have three source clients' do
      expect(GrdaWarehouse::Hud::Client.source.count).to eq(3)
    end

    it 'the database will have four enrollments' do
      expect(GrdaWarehouse::Hud::Enrollment.count).to eq(4)
    end
    it 'the database will have 18 services' do
      expect(GrdaWarehouse::Hud::Service.count).to eq(18)
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
          'spec/fixtures/files/importers/hmis_twenty_twenty/enrollment_change_files',
          version: '2020',
          run_jobs: false,
        )
      end
      after(:all) do
        cleanup_hmis_csv_fixtures
      end

      it 'it imports enrollments that changed but have an earlier modification date because the ExportDate in Export.csv is the most recent date' do
        expect(GrdaWarehouse::Hud::Enrollment.where(PersonalID: '2f4b963171644a8b9902bdfe79a4b403').pluck(:HouseholdID).compact).to eq(['1111'])
      end
      it 'it imports enrollments that changed with an unchanged modification date' do
        expect(GrdaWarehouse::Hud::Enrollment.where(PersonalID: '4c9da990d51b4ed1a2e45b972aeaecee').pluck(:HouseholdID).compact).to eq(['2222'])
      end
      it 'it imports enrollments that changed with a later modification date' do
        expect(GrdaWarehouse::Hud::Enrollment.where(PersonalID: '7b8c1279001142afac2fd0bde7a8f6bf').pluck(:HouseholdID).compact).to eq(['3333'])
      end
    end
  end # end describe enrollments

  describe 'When importing enrollments with deletes' do
    before(:all) do
      import_hmis_csv_fixture(
        'spec/fixtures/files/importers/hmis_twenty_twenty/enrollment_with_deletes_test_files',
        version: '2020',
        run_jobs: false,
      )
    end
    after(:all) do
      # Because we are only running the import once, we have to do our own DB and file cleanup
      GrdaWarehouse::Utility.clear!
      cleanup_hmis_csv_fixtures
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
      described_class.soft_deletable_sources.each do |source|
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
      import_hmis_csv_fixture(
        'spec/fixtures/files/importers/hmis_twenty_twenty/project_test_files',
        version: '2020',
        run_jobs: false,
      )
    end
    after(:all) do
      # Because we are only running the import once, we have to do our own DB and file cleanup
      GrdaWarehouse::Utility.clear!
      cleanup_hmis_csv_fixtures
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

  describe 'When importing enrollments with restores' do
    before(:all) do
      import_hmis_csv_fixture(
        'spec/fixtures/files/importers/hmis_twenty_twenty/enrollment_test_with_restores_initial_files',
        version: '2020',
        run_jobs: false,
      )
      import_hmis_csv_fixture(
        'spec/fixtures/files/importers/hmis_twenty_twenty/enrollment_test_with_restores_update_files',
        version: '2020',
        run_jobs: false,
      )
    end
    after(:all) do
      # Because we are only running the import once, we have to do our own DB and file cleanup
      GrdaWarehouse::Utility.clear!
      cleanup_hmis_csv_fixtures
    end

    it 'has two enrollments' do
      expect(GrdaWarehouse::Hud::Enrollment.count).to eq(2)
    end
  end
end
