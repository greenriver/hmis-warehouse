###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../support/export_helper_2026'

RSpec.describe HmisCsvTwentyTwentySix::Exporter::Base, type: :model do
  describe 'date range filtering' do
    before(:all) do
      cleanup_test_environment
      ExportHelper2026.setup_data

      @start_date = 1.month.ago.to_date
      @end_date = Date.current
      @involved_project_ids = ExportHelper2026.projects.map(&:id)

      # move some data outside the date range
      @old_ce_participations = ExportHelper2026.ce_participations.first(4)
      @old_ce_participations.each do |participation|
        participation.update!(
          CEParticipationStatusStartDate: 3.months.ago,
          CEParticipationStatusEndDate: 2.months.ago,
        )
      end

      @old_hmis_participations = ExportHelper2026.hmis_participations.first(4)
      @old_hmis_participations.each do |participation|
        participation.update!(
          HMISParticipationStatusStartDate: 3.months.ago,
          HMISParticipationStatusEndDate: 2.months.ago,
        )
      end

      @old_funders = ExportHelper2026.funders.first(4)
      @old_funders.each do |funder|
        funder.update!(
          StartDate: 3.months.ago,
          EndDate: 2.months.ago,
        )
      end

      @old_projects = ExportHelper2026.projects.first(4)
      @old_projects.each do |project|
        project.update!(
          OperatingStartDate: 3.months.ago,
          OperatingEndDate: 2.months.ago,
        )
      end

      @old_inventories = ExportHelper2026.inventories.first(4)
      @old_inventories.each do |inventory|
        inventory.update!(
          InventoryStartDate: 3.months.ago,
          InventoryEndDate: 2.months.ago,
        )
      end

      # Create some data within the date range
      @valid_ce_participation = ExportHelper2026.ce_participations.last
      @valid_ce_participation.update!(
        CEParticipationStatusStartDate: 3.weeks.ago,
        CEParticipationStatusEndDate: 2.weeks.ago,
      )

      @valid_hmis_participation = ExportHelper2026.hmis_participations.last
      @valid_hmis_participation.update!(
        HMISParticipationStatusStartDate: 3.weeks.ago,
        HMISParticipationStatusEndDate: 2.weeks.ago,
      )

      @valid_funder = ExportHelper2026.funders.last
      @valid_funder.update!(
        StartDate: 3.weeks.ago,
        EndDate: 2.weeks.ago,
      )

      @valid_project = ExportHelper2026.projects.last
      @valid_project.update!(
        OperatingStartDate: 3.weeks.ago,
        OperatingEndDate: 2.weeks.ago,
      )

      @valid_inventory = ExportHelper2026.inventories.last
      @valid_inventory.update!(
        InventoryStartDate: 3.weeks.ago,
        InventoryEndDate: 2.weeks.ago,
      )
    end

    after(:all) do
      ExportHelper2026.cleanup
    end

    context 'when enforce_project_date_scope is true' do
      before(:each) do
        @exporter = HmisCsvTwentyTwentySix::Exporter::Base.new(
          start_date: @start_date,
          end_date: @end_date,
          projects: @involved_project_ids,
          period_type: 3,
          directive: 3,
          user_id: ExportHelper2026.user.id,
          enforce_project_date_scope: true,
        )
        # this is usually set in the controller
        @exporter.setup_enforce_project_date_scope
        ExportHelper2026.instance_variable_set(:@exporter, @exporter)
        @exporter.export!(cleanup: false, zip: false, upload: false)
      end

      after(:each) do
        @exporter.remove_export_files
      end

      it 'only includes CE Participation records within the specified date range' do
        csv = CSV.read(ExportHelper2026.csv_file_path('CEParticipation'), headers: true)
        expect(csv.count).to eq(1)
        expect(csv.first['CEParticipationID']).to eq(@valid_ce_participation.id.to_s)
      end

      it 'only includes HMIS Participation records within the specified date range' do
        csv = CSV.read(ExportHelper2026.csv_file_path('HMISParticipation'), headers: true)
        expect(csv.count).to eq(1)
        expect(csv.first['HMISParticipationID']).to eq(@valid_hmis_participation.id.to_s)
      end

      it 'only includes Funder records within the specified date range' do
        csv = CSV.read(ExportHelper2026.csv_file_path('Funder'), headers: true)
        expect(csv.count).to eq(1)
        expect(csv.first['FunderID']).to eq(@valid_funder.id.to_s)
      end

      it 'only includes Project records within the specified date range' do
        csv = CSV.read(ExportHelper2026.csv_file_path('Project'), headers: true)
        expect(csv.count).to eq(1)
        expect(csv.first['ProjectID']).to eq(@valid_project.id.to_s)
      end

      it 'only includes Inventory records within the specified date range' do
        csv = CSV.read(ExportHelper2026.csv_file_path('Inventory'), headers: true)
        expect(csv.count).to eq(1)
        expect(csv.first['InventoryID']).to eq(@valid_inventory.id.to_s)
      end
    end

    context 'when enforce_project_date_scope is false' do
      before(:each) do
        @exporter = HmisCsvTwentyTwentySix::Exporter::Base.new(
          start_date: @start_date,
          end_date: @end_date,
          projects: @involved_project_ids,
          period_type: 3,
          directive: 3,
          user_id: ExportHelper2026.user.id,
        )
        ExportHelper2026.instance_variable_set(:@exporter, @exporter)
        @exporter.export!(cleanup: false, zip: false, upload: false)
      end

      after(:each) do
        @exporter.remove_export_files
      end

      it 'includes all CE Participation records regardless of date range' do
        csv = CSV.read(ExportHelper2026.csv_file_path('CEParticipation'), headers: true)
        expect(csv.count).to eq(5) # 4 old + 1 valid
        participation_ids = csv.map { |row| row['CEParticipationID'] }
        expected_ids = @old_ce_participations.map { |m| m.id.to_s } + [@valid_ce_participation.id.to_s]
        expect(participation_ids).to include(*expected_ids)
      end

      it 'includes all HMIS Participation records regardless of date range' do
        csv = CSV.read(ExportHelper2026.csv_file_path('HMISParticipation'), headers: true)
        expect(csv.count).to eq(5) # 4 old + 1 valid
        participation_ids = csv.map { |row| row['HMISParticipationID'] }
        expected_ids = @old_hmis_participations.map { |m| m.id.to_s } + [@valid_hmis_participation.id.to_s]
        expect(participation_ids).to include(*expected_ids)
      end

      it 'includes all Funder records regardless of date range' do
        csv = CSV.read(ExportHelper2026.csv_file_path('Funder'), headers: true)
        expect(csv.count).to eq(5) # 4 old + 1 valid
        funder_ids = csv.map { |row| row['FunderID'] }
        expected_ids = @old_funders.map { |m| m.id.to_s } + [@valid_funder.id.to_s]
        expect(funder_ids).to include(*expected_ids)
      end

      it 'includes all Project records regardless of date range' do
        csv = CSV.read(ExportHelper2026.csv_file_path('Project'), headers: true)
        expect(csv.count).to eq(5) # 4 old + 1 valid
        project_ids = csv.map { |row| row['ProjectID'] }
        expected_ids = @old_projects.map { |m| m.id.to_s } + [@valid_project.id.to_s]
        expect(project_ids).to include(*expected_ids)
      end

      it 'includes all Inventory records regardless of date range' do
        csv = CSV.read(ExportHelper2026.csv_file_path('Inventory'), headers: true)
        expect(csv.count).to eq(5) # 4 old + 1 valid
        inventory_ids = csv.map { |row| row['InventoryID'] }
        expected_ids = @old_inventories.map { |m| m.id.to_s } + [@valid_inventory.id.to_s]
        expect(inventory_ids).to include(*expected_ids)
      end
    end
  end
end
