# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../shared_contexts/hud_enrollment_builders'

RSpec.describe GrdaWarehouse::Census::CensusBuilder, type: :model do
  include_context 'HUD enrollment builders'

  let(:start_date) { '2024-06-01'.to_date }
  let(:end_date) { '2024-07-30'.to_date }

  # Shared context for a standard project with services
  shared_context 'with a standard project and services' do
    let!(:project) { create_project(project_type: 0) } # Default project type
    let!(:client) { create_client_with_warehouse_link }
    let!(:enrollment) do
      create_enrollment(
        client: client,
        project: project,
        entry_date: start_date, # Uses start_date from the outer scope
      )
    end

    before(:each) do
      # Uses start_date and end_date from the outer scope
      (start_date..end_date).each do |date|
        create_bed_night_service(enrollment: enrollment, date: date)
      end
      GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)
    end
  end

  subject { described_class }

  describe '.call' do
    context 'with standard project setup' do
      include_context 'with a standard project and services'

      it 'persists census records for all dates in the range' do
        create(
          :hud_inventory,
          ProjectID: project.project_id,
          data_source: project.data_source,
          InventoryStartDate: start_date,
          InventoryEndDate: end_date,
          BedInventory: 5,
        )

        expect do
          subject.call(start_date, end_date)
        end.to change { GrdaWarehouse::Census::ByProject.where(project_id: project.id, date: start_date..end_date).count }.by((end_date - start_date + 1).to_i)
      end

      context 'inventory date handling' do
        it 'counts beds when all inventory dates are blank' do
          create(
            :hud_inventory,
            ProjectID: project.project_id,
            data_source: project.data_source,
            InformationDate: nil,
            InventoryStartDate: nil,
            InventoryEndDate: nil,
            BedInventory: 10,
          )

          subject.call(start_date, end_date)

          records = GrdaWarehouse::Census::ByProject.where(project_id: project.id)
          expect(records.pluck(:beds).uniq).to eq([10])
        end

        it 'counts beds on boundary dates (inclusive)' do
          create(
            :hud_inventory,
            ProjectID: project.project_id,
            data_source: project.data_source,
            InventoryStartDate: start_date,
            InventoryEndDate: end_date,
            BedInventory: 5,
          )

          subject.call(start_date, end_date)

          record_start = GrdaWarehouse::Census::ByProject.find_by(project_id: project.id, date: start_date)
          expect(record_start.beds).to eq(5)

          record_end = GrdaWarehouse::Census::ByProject.find_by(project_id: project.id, date: end_date)
          expect(record_end.beds).to eq(5)
        end

        it 'continues counting beds when no end date is specified' do
          midpoint = start_date + 15.days
          create(
            :hud_inventory,
            ProjectID: project.project_id,
            data_source: project.data_source,
            InventoryStartDate: midpoint,
            InventoryEndDate: nil,
            BedInventory: 8,
          )

          subject.call(start_date, end_date)

          record_before = GrdaWarehouse::Census::ByProject.find_by(project_id: project.id, date: midpoint - 1.day)
          expect(record_before.beds).to eq(0)

          record_on = GrdaWarehouse::Census::ByProject.find_by(project_id: project.id, date: midpoint)
          expect(record_on.beds).to eq(8)

          record_after = GrdaWarehouse::Census::ByProject.find_by(project_id: project.id, date: end_date)
          expect(record_after.beds).to eq(8)
        end

        it 'handles multiple overlapping inventories correctly' do
          create(
            :hud_inventory,
            ProjectID: project.project_id,
            data_source: project.data_source,
            InventoryStartDate: start_date,
            InventoryEndDate: start_date + 14.days,
            BedInventory: 5,
          )
          create(
            :hud_inventory,
            ProjectID: project.project_id,
            data_source: project.data_source,
            InventoryStartDate: start_date + 9.days,
            InventoryEndDate: start_date + 24.days,
            BedInventory: 3,
          )

          subject.call(start_date, end_date)

          record_early = GrdaWarehouse::Census::ByProject.find_by(project_id: project.id, date: start_date + 5.days)
          expect(record_early.beds).to eq(5)
          record_overlap = GrdaWarehouse::Census::ByProject.find_by(project_id: project.id, date: start_date + 12.days)
          expect(record_overlap.beds).to eq(8)
          record_later = GrdaWarehouse::Census::ByProject.find_by(project_id: project.id, date: start_date + 20.days)
          expect(record_later.beds).to eq(3)
          record_after = GrdaWarehouse::Census::ByProject.find_by(project_id: project.id, date: start_date + 26.days)
          expect(record_after.beds).to eq(0)
        end
      end

      context 'population counts with multiple services for a single client on the same day' do
        let(:test_date) { start_date }
        let(:test_population_column) do
          populations = GrdaWarehouse::Census.census_populations
          raise 'Cannot determine a test population column from GrdaWarehouse::Census.census_populations. ' if populations.nil? || populations.empty? || !populations.first.is_a?(Hash) || !populations.first.key?(:population)

          populations.first[:population]
        end

        it 'counts the client only once per day for that population' do
          create_bed_night_service(enrollment: enrollment, date: test_date)
          GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)

          subject.call(start_date, end_date)

          census_record = GrdaWarehouse::Census::ByProject.find_by(project_id: project.id, date: test_date)
          expect(census_record).not_to be_nil
          actual_count = census_record[test_population_column]
          expect(actual_count).to eq(1), "Client should be counted once for population '#{test_population_column}' on #{test_date}. Got #{actual_count}."
        end
      end

      context 'when a project has population services but no inventory' do
        let(:test_population_column) do
          populations = GrdaWarehouse::Census.census_populations
          raise 'Cannot determine a test population column from GrdaWarehouse::Census.census_populations. ' if populations.nil? || populations.empty? || !populations.first.is_a?(Hash) || !populations.first.key?(:population)

          populations.first[:population]
        end

        it 'creates census records with population counts and zero bed counts' do
          subject.call(start_date, end_date)

          records = GrdaWarehouse::Census::ByProject.where(project_id: project.id, date: start_date..end_date)
          expect(records.count).to eq((end_date - start_date + 1).to_i)

          records.each do |record|
            expect(record.beds).to eq(0)
            expect(record[test_population_column]).to be >= 1
          end
        end
      end
    end # end of "with standard project setup"

    context 'when a project has inventory but no population services' do
      # This context has its own isolated setup
      let!(:inventory_only_project) { create_project(project_type: 1) }
      let(:inventory_beds) { 7 }

      before do
        create(
          :hud_inventory,
          ProjectID: inventory_only_project.project_id,
          data_source: inventory_only_project.data_source,
          InventoryStartDate: start_date,
          InventoryEndDate: end_date,
          BedInventory: inventory_beds,
        )
        # No services for inventory_only_project
      end

      it 'does not create census records with bed counts' do
        subject.call(start_date, end_date)
        records = GrdaWarehouse::Census::ByProject.where(project_id: inventory_only_project.id, date: start_date..end_date)
        expect(records.count).to be_zero
      end
    end

    context 'when a project serves clients in multiple distinct populations on the same day' do
      let!(:multi_pop_project) { create_project(project_type: 2) }
      let(:multi_pop_test_date) { start_date }

      let(:defined_population_columns) { [:all_clients, :non_veterans, :veterans] }

      before do
        # Client 1: Veteran
        client_veteran = create_client_with_warehouse_link(veteran_status: 1)
        enrollment_veteran = create_enrollment(
          client: client_veteran,
          project: multi_pop_project,
          entry_date: multi_pop_test_date,
        )
        create_bed_night_service(enrollment: enrollment_veteran, date: multi_pop_test_date)

        # Client 2: Non-Veteran
        client_non_veteran = create_client_with_warehouse_link(veteran_status: 0)
        enrollment_non_veteran = create_enrollment(
          client: client_non_veteran,
          project: multi_pop_project,
          entry_date: multi_pop_test_date,
        )
        create_bed_night_service(enrollment: enrollment_non_veteran, date: multi_pop_test_date)

        GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)
      end

      it 'populates counts correctly for all_clients, veterans, and non_veterans' do
        expect(defined_population_columns).to eq(GrdaWarehouse::Census.census_populations.map { |p| p[:population] }.uniq)
        subject.call(multi_pop_test_date, multi_pop_test_date) # User removed project_ids filter here, assuming it's okay

        record = GrdaWarehouse::Census::ByProject.find_by(project_id: multi_pop_project.id, date: multi_pop_test_date)
        expect(record).not_to be_nil,
                              "Census record for project #{multi_pop_project.id} on #{multi_pop_test_date} not found."

        expect(record[:all_clients]).to eq(2), "Expected count for :all_clients to be 2, got #{record[:all_clients]}"
        expect(record[:veterans]).to eq(1), "Expected count for :veterans to be 1, got #{record[:veterans]}"
        expect(record[:non_veterans]).to eq(1), "Expected count for :non_veterans to be 1, got #{record[:non_veterans]}"

        # Check that other defined population columns (if any) are zero
        other_pop_cols = defined_population_columns - [:all_clients, :veterans, :non_veterans]
        other_pop_cols.each do |other_pop_col|
          expect(record[other_pop_col]).to eq(0),
                                           "Expected count for other population '#{other_pop_col}' to be 0, got #{record[other_pop_col]}"
        end
      end
    end
  end
end
