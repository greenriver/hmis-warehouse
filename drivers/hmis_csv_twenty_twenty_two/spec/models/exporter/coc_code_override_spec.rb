###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'export_helper'

RSpec.describe HmisCsvTwentyTwentyTwo::Exporter::Base, type: :model do
  def override_coc_codes
    @projects.each do |item|
      item.update(ProjectType: 1, act_as_project_type: 13, computed_project_type: 13)
    end
    @project_cocs.each do |item|
      item.update(CoCCode: 'XX-500')
    end
    @inventories.each do |item|
      item.update(CoCCode: 'XX-501')
    end
    @enrollment_cocs.each do |item|
      item.update(CoCCode: 'XX-505')
    end
  end

  def warehouse_fixture
    @warehouse_fixture ||= PgFixtures.new(
      directory: 'drivers/hmis_csv_twenty_twenty_two/spec/fixpoints',
      excluded_tables: default_excluded_tables,
      model: GrdaWarehouseBase,
    )
  end

  def app_fixture
    @app_fixture ||= PgFixtures.new(
      directory: 'drivers/hmis_csv_twenty_twenty_two/spec/fixpoints',
      excluded_tables: ['versions'],
      model: ApplicationRecord,
    )
  end

  before(:all) do
    self.use_transactional_tests = false
    cleanup_test_environment
    if warehouse_fixture.exists? && app_fixture.exists?
      warehouse_fixture.restore
      app_fixture.restore
    else
      setup_data
      override_coc_codes

      warehouse_fixture.store
      app_fixture.store
    end
    @exporter = HmisCsvTwentyTwentyTwo::Exporter::Base.new(
      start_date: 1.week.ago.to_date,
      end_date: Date.current,
      projects: [@projects.first.id],
      period_type: 3,
      directive: 3,
      user_id: @user.id,
    )
    @exporter.export!(cleanup: false, zip: false, upload: false)
  end

  after(:all) do
    @exporter.remove_export_files
    cleanup_test_environment
    self.use_transactional_tests = true
  end

  describe 'When exporting enrollment related item' do
    [
      HmisCsvTwentyTwentyTwo::Exporter::EnrollmentCoc,
      HmisCsvTwentyTwentyTwo::Exporter::Inventory,
      HmisCsvTwentyTwentyTwo::Exporter::ProjectCoc,
    ].each do |klass|
      describe "when exporting #{klass}" do
        it 'enrollment scope should find one enrollment' do
          expect(@exporter.enrollment_scope.count).to eq 1
        end
        it 'creates one CSV file' do
          expect(File.exist?(csv_file_path(klass))).to be true
        end
        it "adds one row to the #{klass} CSV file" do
          csv = CSV.read(csv_file_path(klass), headers: true)
          expect(csv.count).to eq 1
        end
        it "CoCCode from CSV matches CoCCode from #{klass}" do
          csv = CSV.read(csv_file_path(klass), headers: true)
          expect(csv.first['CoCCode']).to eq klass.hmis_class.first.CoCCode.to_s
        end
      end
    end

    describe 'when CoC Code is missing' do
      [
        HmisCsvTwentyTwentyTwo::Exporter::EnrollmentCoc,
        HmisCsvTwentyTwentyTwo::Exporter::Inventory,
      ].each do |klass|
        describe "when exporting #{klass}" do
          before(:all) do
            warehouse_fixture.restore
            app_fixture.restore
            klass.hmis_class.update_all(CoCCode: nil)
            @exporter.remove_export_files
            @exporter.export!(cleanup: false, zip: false, upload: false)
          end

          it "adds one row to the #{klass} CSV file" do
            csv = CSV.read(csv_file_path(klass), headers: true)
            expect(csv.count).to eq 1
          end
          it 'CoCCode from CSV matches CoCCode from ProjectCoC' do
            csv = CSV.read(csv_file_path(klass), headers: true)
            expect(csv.first['CoCCode']).to eq @project_cocs.first.CoCCode.to_s
          end
        end
        describe "when exporting #{klass} and Project has more than one CoCCode" do
          # This needs to happen in a transaction so that the project CoC records are reset for the next run
          # so, slower but we're using before(:each)
          before(:each) do
            klass.hmis_class.update_all(CoCCode: nil)
            # Force project to have multiple distinct CoC Codes
            GrdaWarehouse::Hud::ProjectCoc.
              joins(:project).
              merge(GrdaWarehouse::Hud::Project.where.not(id: @projects.first.id)).
              update_all(
                ProjectID: @projects.first.ProjectID,
                CoCCode: 'XX-505',
                data_source_id: @projects.first.data_source_id,
              )
            @exporter.remove_export_files
            @exporter.export!(cleanup: false, zip: false, upload: false)
          end

          it "adds one row to the #{klass} CSV file" do
            csv = CSV.read(csv_file_path(klass), headers: true)
            expect(csv.count).to eq 1
          end
          it 'CoCCode from CSV is blank' do
            csv = CSV.read(csv_file_path(klass), headers: true)
            expect(csv.first['CoCCode']).to be_blank
          end
        end
      end
    end
  end

  describe 'When exporting enrollment related item' do
    [
      HmisCsvTwentyTwentyTwo::Exporter::EnrollmentCoc,
    ].each do |klass|
      describe "when exporting #{klass}" do
        before(:all) do
          warehouse_fixture.restore
          app_fixture.restore
          @exporter.remove_export_files
          @exporter.export!(cleanup: false, zip: false, upload: false)
        end
        it 'enrollment scope should find one enrollment' do
          expect(@exporter.enrollment_scope.count).to eq 1
        end
        it 'creates one CSV file' do
          expect(File.exist?(csv_file_path(klass))).to be true
        end
        it "adds one row to the #{klass} CSV file" do
          csv = CSV.read(csv_file_path(klass), headers: true)
          expect(csv.count).to eq 1
        end
        it 'ProjectID from CSV matches ProjectID from EnrollmentCoC' do
          csv = CSV.read(csv_file_path(klass), headers: true)
          # Note, by the time this gets exported, it is re-written to the project.id
          expect(csv.first['ProjectID']).to eq @projects.first.id.to_s
        end
      end
    end

    describe 'when Project ID is missing' do
      [
        HmisCsvTwentyTwentyTwo::Exporter::EnrollmentCoc,
      ].each do |klass|
        describe "when exporting #{klass}" do
          before(:all) do
            warehouse_fixture.restore
            app_fixture.restore
            klass.hmis_class.update_all(ProjectID: nil)
            @exporter.remove_export_files
            @exporter.export!(cleanup: false, zip: false, upload: false)
          end

          it "adds one row to the #{klass} CSV file" do
            csv = CSV.read(csv_file_path(klass), headers: true)
            expect(csv.count).to eq 1
          end
          it 'ProjectID from CSV matches ProjectID from Enrollment' do
            csv = CSV.read(csv_file_path(klass), headers: true)
            expect(csv.first['ProjectID']).to eq @projects.first.id.to_s
          end
        end
      end
    end
  end
end
