# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../shared_contexts/hud_enrollment_builders'

RSpec.describe GrdaWarehouse::Census::CensusBuilder, type: :model do
  include_context 'HUD enrollment builders'

  let(:start_date) { '2024-06-01'.to_date }
  let(:end_date) { '2024-07-30'.to_date }

  before do
    @project = create_project(project_type: 0)
    @client = create_client_with_warehouse_link
    @enrollment = create_enrollment(
      client: @client,
      project: @project,
      entry_date: start_date,
    )
    (start_date..end_date).each do |date|
      create_bed_night_service(enrollment: @enrollment, date: date)
    end
    GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)
  end

  subject { described_class.new }

  describe '#create_census' do
    it 'persists census records for all dates in the range' do
      create(:hud_inventory,
             ProjectID: @project.project_id,
             data_source: @project.data_source,
             InventoryStartDate: start_date,
             InventoryEndDate: end_date,
             BedInventory: 5)

      expect do
        subject.create_census(start_date, end_date)
      end.to change { GrdaWarehouse::Census::ByProject.where(project_id: @project.id, date: start_date..end_date).count }.by((end_date - start_date + 1).to_i)
    end

    context 'inventory date handling' do
      it 'counts beds when all inventory dates are blank' do
        create(:hud_inventory,
               ProjectID: @project.project_id,
               data_source: @project.data_source,
               InformationDate: nil,
               InventoryStartDate: nil,
               InventoryEndDate: nil,
               BedInventory: 10)

        subject.create_census(start_date, end_date)

        records = GrdaWarehouse::Census::ByProject.where(project_id: @project.id)
        expect(records.pluck(:beds).uniq).to eq([10])
      end

      it 'counts beds on boundary dates (inclusive)' do
        create(:hud_inventory,
               ProjectID: @project.project_id,
               data_source: @project.data_source,
               InventoryStartDate: start_date,
               InventoryEndDate: end_date,
               BedInventory: 5)

        subject.create_census(start_date, end_date)

        # Check start boundary
        record_start = GrdaWarehouse::Census::ByProject.find_by(project_id: @project.id, date: start_date)
        expect(record_start.beds).to eq(5)

        # Check end boundary
        record_end = GrdaWarehouse::Census::ByProject.find_by(project_id: @project.id, date: end_date)
        expect(record_end.beds).to eq(5)
      end

      it 'continues counting beds when no end date is specified' do
        midpoint = start_date + 15.days
        create(:hud_inventory,
               ProjectID: @project.project_id,
               data_source: @project.data_source,
               InventoryStartDate: midpoint,
               InventoryEndDate: nil,
               BedInventory: 8)

        subject.create_census(start_date, end_date)

        # Before start date
        record_before = GrdaWarehouse::Census::ByProject.find_by(project_id: @project.id, date: midpoint - 1.day)
        expect(record_before.beds).to eq(0)

        # On and after start date
        record_on = GrdaWarehouse::Census::ByProject.find_by(project_id: @project.id, date: midpoint)
        expect(record_on.beds).to eq(8)

        record_after = GrdaWarehouse::Census::ByProject.find_by(project_id: @project.id, date: end_date)
        expect(record_after.beds).to eq(8)
      end

      it 'handles multiple overlapping inventories correctly' do
        # First inventory: days 1-15 with 5 beds
        create(:hud_inventory,
               ProjectID: @project.project_id,
               data_source: @project.data_source,
               InventoryStartDate: start_date,
               InventoryEndDate: start_date + 14.days,
               BedInventory: 5)

        # Second inventory: days 10-25 with 3 beds
        create(:hud_inventory,
               ProjectID: @project.project_id,
               data_source: @project.data_source,
               InventoryStartDate: start_date + 9.days,
               InventoryEndDate: start_date + 24.days,
               BedInventory: 3)

        subject.create_census(start_date, end_date)

        # Days 1-9: only first inventory (5 beds)
        record_early = GrdaWarehouse::Census::ByProject.find_by(project_id: @project.id, date: start_date + 5.days)
        expect(record_early.beds).to eq(5)

        # Days 10-15: both inventories (5 + 3 = 8 beds)
        record_overlap = GrdaWarehouse::Census::ByProject.find_by(project_id: @project.id, date: start_date + 12.days)
        expect(record_overlap.beds).to eq(8)

        # Days 16-25: only second inventory (3 beds)
        record_later = GrdaWarehouse::Census::ByProject.find_by(project_id: @project.id, date: start_date + 20.days)
        expect(record_later.beds).to eq(3)

        # Days 26+: no inventory (0 beds)
        record_after = GrdaWarehouse::Census::ByProject.find_by(project_id: @project.id, date: start_date + 26.days)
        expect(record_after.beds).to eq(0)
      end
    end
  end
end
