# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../shared_contexts/hud_enrollment_builders'

RSpec.describe GrdaWarehouse::Census::CensusBuilder, type: :model do
  include_context 'HUD enrollment builders'

  let(:start_date) { '2024-06-01'.to_date }
  let(:end_date) { '2024-07-30'.to_date }
  let(:project_type) { 0 } # Default project type, can be overridden in contexts

  let!(:project) { create_project(project_type: project_type) }
  let!(:client) { create_client_with_warehouse_link }
  let!(:enrollment) do
    create_enrollment(
      client: client,
      project: project,
      entry_date: start_date,
    )
  end

  # Helper to set up initial services and rebuild history
  def setup_initial_services_and_rebuild_history
    (start_date..end_date).each do |date|
      create_bed_night_service(enrollment: enrollment, date: date)
    end
    GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)
  end

  subject { described_class }

  describe '.call' do
    before(:each) do
      # Ensure services are created and history rebuilt for each test in this describe block
      setup_initial_services_and_rebuild_history
    end

    it 'persists census records for all dates in the range' do
      create(:hud_inventory,
             ProjectID: project.project_id, # Use let variable
             data_source: project.data_source, # Use let variable
             InventoryStartDate: start_date,
             InventoryEndDate: end_date,
             BedInventory: 5)

      expect do
        subject.call(start_date, end_date)
      end.to change { GrdaWarehouse::Census::ByProject.where(project_id: project.id, date: start_date..end_date).count }.by((end_date - start_date + 1).to_i)
    end

    context 'inventory date handling' do
      it 'counts beds when all inventory dates are blank' do
        create(:hud_inventory,
               ProjectID: project.project_id, # Use let variable
               data_source: project.data_source, # Use let variable
               InformationDate: nil,
               InventoryStartDate: nil,
               InventoryEndDate: nil,
               BedInventory: 10)

        subject.call(start_date, end_date)

        records = GrdaWarehouse::Census::ByProject.where(project_id: project.id)
        expect(records.pluck(:beds).uniq).to eq([10])
      end

      it 'counts beds on boundary dates (inclusive)' do
        create(:hud_inventory,
               ProjectID: project.project_id, # Use let variable
               data_source: project.data_source, # Use let variable
               InventoryStartDate: start_date,
               InventoryEndDate: end_date,
               BedInventory: 5)

        subject.call(start_date, end_date)

        # Check start boundary
        record_start = GrdaWarehouse::Census::ByProject.find_by(project_id: project.id, date: start_date)
        expect(record_start.beds).to eq(5)

        # Check end boundary
        record_end = GrdaWarehouse::Census::ByProject.find_by(project_id: project.id, date: end_date)
        expect(record_end.beds).to eq(5)
      end

      it 'continues counting beds when no end date is specified' do
        midpoint = start_date + 15.days
        create(:hud_inventory,
               ProjectID: project.project_id, # Use let variable
               data_source: project.data_source, # Use let variable
               InventoryStartDate: midpoint,
               InventoryEndDate: nil,
               BedInventory: 8)

        subject.call(start_date, end_date)

        # Before start date
        record_before = GrdaWarehouse::Census::ByProject.find_by(project_id: project.id, date: midpoint - 1.day)
        expect(record_before.beds).to eq(0)

        # On and after start date
        record_on = GrdaWarehouse::Census::ByProject.find_by(project_id: project.id, date: midpoint)
        expect(record_on.beds).to eq(8)

        record_after = GrdaWarehouse::Census::ByProject.find_by(project_id: project.id, date: end_date)
        expect(record_after.beds).to eq(8)
      end

      it 'handles multiple overlapping inventories correctly' do
        # First inventory: days 1-15 with 5 beds
        create(:hud_inventory,
               ProjectID: project.project_id, # Use let variable
               data_source: project.data_source, # Use let variable
               InventoryStartDate: start_date,
               InventoryEndDate: start_date + 14.days,
               BedInventory: 5)

        # Second inventory: days 10-25 with 3 beds
        create(:hud_inventory,
               ProjectID: project.project_id, # Use let variable
               data_source: project.data_source, # Use let variable
               InventoryStartDate: start_date + 9.days,
               InventoryEndDate: start_date + 24.days,
               BedInventory: 3)

        subject.call(start_date, end_date)

        # Days 1-9: only first inventory (5 beds)
        record_early = GrdaWarehouse::Census::ByProject.find_by(project_id: project.id, date: start_date + 5.days)
        expect(record_early.beds).to eq(5)

        # Days 10-15: both inventories (5 + 3 = 8 beds)
        record_overlap = GrdaWarehouse::Census::ByProject.find_by(project_id: project.id, date: start_date + 12.days)
        expect(record_overlap.beds).to eq(8)

        # Days 16-25: only second inventory (3 beds)
        record_later = GrdaWarehouse::Census::ByProject.find_by(project_id: project.id, date: start_date + 20.days)
        expect(record_later.beds).to eq(3)

        # Days 26+: no inventory (0 beds)
        record_after = GrdaWarehouse::Census::ByProject.find_by(project_id: project.id, date: start_date + 26.days)
        expect(record_after.beds).to eq(0)
      end
    end

    context 'population counts with multiple services for a single client on the same day' do
      let(:test_date) { start_date } # Keep using start_date from outer scope
      let(:test_population_column) do
        populations = GrdaWarehouse::Census.census_populations
        raise 'Cannot determine a test population column from GrdaWarehouse::Census.census_populations. ' if populations.nil? || populations.empty? || !populations.first.is_a?(Hash) || !populations.first.key?(:population)

        populations.first[:population]
      end

      it 'counts the client only once per day for that population' do
        # The `before(:each)` block in the parent `describe` has already run,
        # creating initial services and rebuilding history.

        # Add a second service for the same client, project, and date.
        # Ensure this service aligns with the `test_population_column` if specific service types are needed.
        # For now, assuming create_bed_night_service is sufficient for the first population type.
        create_bed_night_service(enrollment: enrollment, date: test_date)

        # Rebuild service history to include the newly added service.
        GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)

        subject.call(start_date, end_date)

        census_record = GrdaWarehouse::Census::ByProject.find_by(project_id: project.id, date: test_date)
        expect(census_record).not_to be_nil, "Census record for project #{project.id} on #{test_date} not found."

        actual_count = census_record[test_population_column]
        expect(actual_count).to eq(1), "Client should be counted once for population '#{test_population_column}' on #{test_date}. Got #{actual_count}."
      end
    end

    context 'when a project has inventory but no population services' do
      let!(:inventory_only_project) { create_project(project_type: 1) }
      let(:inventory_beds) { 7 }

      before do
        create(:hud_inventory,
               ProjectID: inventory_only_project.project_id,
               data_source: inventory_only_project.data_source,
               InventoryStartDate: start_date,
               InventoryEndDate: end_date,
               BedInventory: inventory_beds)
        # No services or enrollments created for inventory_only_project
      end

      it 'does not create census records with bed counts' do
        subject.call(start_date, end_date)

        # this behavior is somewhat unintuitive
        records = GrdaWarehouse::Census::ByProject.where(project_id: inventory_only_project.id, date: start_date..end_date)
        expect(records.count).to be_zero
      end
    end

    context 'when a project has population services but no inventory' do
      # This context uses the global `project`, `client`, `enrollment`,
      # and the services set up by `setup_initial_services_and_rebuild_history`.
      # We just ensure no inventory is created for `project` in this specific scope.

      let(:test_population_column) do # Re-define for this context if needed, or rely on outer one
        populations = GrdaWarehouse::Census.census_populations
        raise 'Cannot determine a test population column from GrdaWarehouse::Census.census_populations. ' if populations.nil? || populations.empty? || !populations.first.is_a?(Hash) || !populations.first.key?(:population)

        populations.first[:population]
      end

      it 'creates census records with population counts and zero bed counts' do
        # Ensure no inventory is associated with the main `project` for this test.
        # GrdaWarehouse::Hud::Inventory.where(ProjectID: project.project_id).delete_all # If any could exist by chance

        subject.call(start_date, end_date)

        records = GrdaWarehouse::Census::ByProject.where(project_id: project.id, date: start_date..end_date)
        expect(records.count).to eq((end_date - start_date + 1).to_i)

        records.each do |record|
          expect(record.beds).to eq(0)
          # Assuming setup_initial_services_and_rebuild_history creates services that affect at least test_population_column
          # The exact count for test_population_column might be 1 if one client per day is standard.
          expect(record[test_population_column]).to be >= 1, "Expected population '#{test_population_column}' to be >= 1, got #{record[test_population_column]}"
          # Other populations might be 0, this depends on the setup
        end
      end
    end
  end
end
