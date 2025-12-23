###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../../shared_contexts/hud_enrollment_builders'

RSpec.describe GrdaWarehouse::Monitoring::MetricCalculators::MaxHouseholdSizeCalculator, type: :model do
  include_context 'HUD enrollment builders'

  let(:calculation_date) { Date.current }
  let(:project) { create_project(project_type: 1) } # ES

  let(:client1) { create_client_with_warehouse_link }
  let(:dest_client1) { client1.destination_client }

  let(:client2) { create_client_with_warehouse_link }
  let(:dest_client2) { client2.destination_client }

  let(:client3) { create_client_with_warehouse_link }
  let(:dest_client3) { client3.destination_client }

  describe '.calculate_batch' do
    context 'when client has no enrollments' do
      it 'returns empty hash' do
        result = described_class.calculate_batch(
          [dest_client1],
          calculation_date,
        )

        expect(result).to eq({})
      end
    end

    context 'when client has single household of size 1' do
      before do
        create_enrollment(
          client: client1,
          project: project,
          entry_date: 30.days.ago,
          household_id: 'HH1',
        )
      end

      it 'returns max size of 1' do
        result = described_class.calculate_batch(
          [dest_client1],
          calculation_date,
        )

        expect(result[dest_client1.id]).to eq(1)
      end
    end

    context 'when client has household of size 3' do
      let(:other_client1) { create_client_with_warehouse_link }
      let(:other_client2) { create_client_with_warehouse_link }

      before do
        # Create household with 3 members
        create_enrollment(
          client: client1,
          project: project,
          entry_date: 30.days.ago,
          household_id: 'HH1',
        )
        create_enrollment(
          client: other_client1,
          project: project,
          entry_date: 30.days.ago,
          household_id: 'HH1',
        )
        create_enrollment(
          client: other_client2,
          project: project,
          entry_date: 30.days.ago,
          household_id: 'HH1',
        )
      end

      it 'returns max size of 3' do
        result = described_class.calculate_batch(
          [dest_client1],
          calculation_date,
        )

        expect(result[dest_client1.id]).to eq(3)
      end
    end

    context 'when client has multiple households of different sizes' do
      let(:other_client) { create_client_with_warehouse_link }

      before do
        # Household of size 1
        create_enrollment(
          client: client1,
          project: project,
          entry_date: 60.days.ago,
          household_id: 'HH1',
        )

        # Household of size 2
        create_enrollment(
          client: client1,
          project: project,
          entry_date: 30.days.ago,
          household_id: 'HH2',
        )
        create_enrollment(
          client: other_client,
          project: project,
          entry_date: 30.days.ago,
          household_id: 'HH2',
        )
      end

      it 'returns maximum household size' do
        result = described_class.calculate_batch(
          [dest_client1],
          calculation_date,
        )

        expect(result[dest_client1.id]).to eq(2)
      end
    end

    context 'when households span multiple data sources' do
      let(:data_source2) { create(:source_data_source) }
      let(:organization2) { create(:hud_organization, data_source: data_source2) }
      let(:project2) { create_project(project_type: 1) }
      let(:other_client) { create_client_with_warehouse_link }

      # Create source client in second data source linked to same destination
      let!(:client1_in_ds2) do
        source_client = create(
          :hud_client,
          personal_id: SecureRandom.uuid.gsub(/-/, ''),
          data_source: data_source2,
        )
        create(
          :warehouse_client,
          destination_id: dest_client1.id,
          source_id: source_client.id,
        )
        source_client
      end

      before do
        # HH1 in data_source: size 1
        create_enrollment(
          client: client1,
          project: project,
          entry_date: 60.days.ago,
          household_id: 'HH1',
        )

        # HH1 in data_source2: size 2 (same HouseholdID but different data source)
        create(
          :hud_enrollment,
          client: client1_in_ds2,
          project: project2,
          data_source: data_source2,
          entry_date: 30.days.ago,
          household_id: 'HH1',
        )
        create(
          :hud_enrollment,
          client: other_client,
          project: project2,
          data_source: data_source2,
          entry_date: 30.days.ago,
          household_id: 'HH1',
        )
      end

      it 'treats households in different data sources separately' do
        result = described_class.calculate_batch(
          [dest_client1],
          calculation_date,
        )

        expect(result[dest_client1.id]).to eq(2)
      end
    end

    context 'when processing multiple clients' do
      before do
        # client1 and client2: household of size 2
        create_enrollment(
          client: client1,
          project: project,
          entry_date: 30.days.ago,
          household_id: 'HH1',
        )
        create_enrollment(
          client: client2,
          project: project,
          entry_date: 30.days.ago,
          household_id: 'HH1',
        )

        # client3: household of size 1
        create_enrollment(
          client: client3,
          project: project,
          entry_date: 30.days.ago,
          household_id: 'HH2',
        )
      end

      it 'returns hash with values for all clients with data' do
        result = described_class.calculate_batch(
          [dest_client1, dest_client2, dest_client3],
          calculation_date,
        )

        expect(result).to be_a(Hash)
        expect(result[dest_client1.id]).to eq(2)
        expect(result[dest_client2.id]).to eq(2)
        expect(result[dest_client3.id]).to eq(1)
      end
    end
  end

  describe '.metric_definition_attributes' do
    let(:attrs) { described_class.metric_definition_attributes }

    it 'returns hash with required attributes' do
      expect(attrs).to include(
        name: 'max_household_size',
        entity_type: 'GrdaWarehouse::Hud::Client',
        calculator_class: described_class.name,
        count_change_threshold: 1,
      )
    end

    it 'includes display name and description' do
      expect(attrs[:display_name]).to be_present
      expect(attrs[:description]).to be_present
    end
  end
end
