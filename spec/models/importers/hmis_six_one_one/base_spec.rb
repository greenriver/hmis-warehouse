require 'rails_helper'

RSpec.describe Importers::HMISSixOneOne::Base, type: :model do
  describe 'When importing enrollments' do
    before(:all) do
      @data_source = GrdaWarehouse::DataSource.create(name: 'Green River', short_name: 'GR', source_type: :sftp)
      @file_path = 'spec/fixtures/files/importers/hmis_six_on_one/enrollment_test_files'
      @source_file_path = File.join(@file_path, 'source')
      @import_path = File.join(@file_path, @data_source.id.to_s)
      # duplicate the fixture file as it gets manipulated
      FileUtils.cp_r(@source_file_path, @import_path)
  
      importer = Importers::HMISSixOneOne::Base.new(file_path: @file_path, data_source_id: @data_source.id, remove_files: false)
      importer.import!
    end
    after(:all) do
      # Because we are only running the import once, we have to do our own DB and file cleanup
      GrdaWarehouse::Utility.clear!
      FileUtils.rm_rf(@import_path) unless @import_path == @file_path
    end
  
    it 'the database will have three clients' do
      expect(GrdaWarehouse::Hud::Client.count).to eq(3)
    end
    it 'the database will have four enrollments' do
      expect(GrdaWarehouse::Hud::Enrollment.count).to eq(4)
    end
    it 'the database will have 18 services' do
      expect(GrdaWarehouse::Hud::Service.count).to eq(18)
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
  end # end describe enrollments

  describe 'When importing enrollments with deletes' do
    before(:all) do
      @data_source = GrdaWarehouse::DataSource.create(name: 'Green River', short_name: 'GR', source_type: :sftp)
      @file_path = 'spec/fixtures/files/importers/hmis_six_on_one/enrollment_with_deletes_test_files'
      @source_file_path = File.join(@file_path, 'source')
      @import_path = File.join(@file_path, @data_source.id.to_s)
      # duplicate the fixture file as it gets manipulated
      FileUtils.cp_r(@source_file_path, @import_path)
  
      importer = Importers::HMISSixOneOne::Base.new(file_path: @file_path, data_source_id: @data_source.id, remove_files: false)
      importer.import!
    end
    after(:all) do
      # Because we are only running the import once, we have to do our own DB and file cleanup
      GrdaWarehouse::Utility.clear!
      FileUtils.rm_rf(@import_path) unless @import_path == @file_path
    end
  
    it 'the database will have two clients' do
      expect(GrdaWarehouse::Hud::Client.count).to eq(2)
    end
    it 'the database will have two enrollments' do
      expect(GrdaWarehouse::Hud::Enrollment.count).to eq(2)
    end
    it 'the database will have 15 services' do
      expect(GrdaWarehouse::Hud::Service.count).to eq(15)
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
      @data_source = GrdaWarehouse::DataSource.create(name: 'Green River', short_name: 'GR', source_type: :sftp)
      @file_path = 'spec/fixtures/files/importers/hmis_six_on_one/project_test_files'
      @source_file_path = File.join(@file_path, 'source')
      @import_path = File.join(@file_path, @data_source.id.to_s)
      # duplicate the fixture file as it gets manipulated
      FileUtils.cp_r(@source_file_path, @import_path)
  
      importer = Importers::HMISSixOneOne::Base.new(file_path: @file_path, data_source_id: @data_source.id, remove_files: false)
      importer.import!
    end
    after(:all) do
      # Because we are only running the import once, we have to do our own DB and file cleanup
      GrdaWarehouse::Utility.clear!
      FileUtils.rm_rf(@import_path) unless @import_path == @file_path
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
    it 'the database will have four geographies' do
      expect(GrdaWarehouse::Hud::Site.count).to eq(4)
    end
    it 'the database will have five funders' do
      expect(GrdaWarehouse::Hud::Funder.count).to eq(5)
    end
    it 'organization 108 has two projects' do
      expect(GrdaWarehouse::Hud::Organization.where(OrganizationID: 108).first.projects.count).to eq(2)
    end

    describe "projects have appropriate relations" do
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
end
