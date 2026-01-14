###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  include_context 'hmis base setup'
  let!(:access_control) { create_access_control(hmis_user, p1) }

  let(:query) do
    <<~GRAPHQL
      query GetProjectUnitTypes($id: ID!) {
        project(id: $id) {
          id
          unitTypes {
            id
            unitType
            capacity
            availability
          }
        }
      }
    GRAPHQL
  end

  describe 'project unitTypes query' do
    before(:each) do
      hmis_login(user)
    end

    context 'when project has units with different unit types' do
      let!(:unit_type_1) { create(:hmis_unit_type, description: '1 Bedroom') }
      let!(:unit_type_2) { create(:hmis_unit_type, description: '2 Bedroom') }
      let!(:unit_type_3) { create(:hmis_unit_type, description: 'Studio') }

      before do
        # Create units for unit_type_1: 3 total, 1 occupied (2 available)
        create_list(:hmis_unit, 3, project: p1, unit_type: unit_type_1, user: hmis_user)
        occupied_unit = p1.units.where(unit_type: unit_type_1).first
        create(:hmis_unit_occupancy, unit: occupied_unit, start_date: 1.week.ago)

        # Create units for unit_type_2: 2 total, all available
        create_list(:hmis_unit, 2, project: p1, unit_type: unit_type_2, user: hmis_user)

        # Create units for unit_type_3: 1 total, 1 occupied (0 available)
        unit_3 = create(:hmis_unit, project: p1, unit_type: unit_type_3, user: hmis_user)
        create(:hmis_unit_occupancy, unit: unit_3, start_date: 2.days.ago)
      end

      it 'returns unit types with correct capacity and availability' do
        response, result = post_graphql(id: p1.id) { query }

        expect(response.status).to eq(200), result.inspect
        unit_types = result.dig('data', 'project', 'unitTypes')

        expect(unit_types.length).to eq(3)

        # Results should be ordered by unit_type.id
        unit_types_by_description = unit_types.index_by { |ut| ut['unitType'] }

        expect(unit_types_by_description['1 Bedroom']).to include(
          'id' => unit_type_1.id.to_s,
          'unitType' => '1 Bedroom',
          'capacity' => 3,
          'availability' => 2,
        )

        expect(unit_types_by_description['2 Bedroom']).to include(
          'id' => unit_type_2.id.to_s,
          'unitType' => '2 Bedroom',
          'capacity' => 2,
          'availability' => 2,
        )

        expect(unit_types_by_description['Studio']).to include(
          'id' => unit_type_3.id.to_s,
          'unitType' => 'Studio',
          'capacity' => 1,
          'availability' => 0,
        )
      end
    end

    context 'with many unit types and units' do
      before do
        # Create 20 different unit types, each with 10 units, half occupied
        20.times do |i|
          unit_type = create(:hmis_unit_type, description: "Unit Type #{i}")

          # Create 10 units for this type
          units = create_list(:hmis_unit, 10, project: p1, unit_type: unit_type, user: hmis_user)

          # Occupy half of them
          units.first(5).each do |unit|
            create(:hmis_unit_occupancy, unit: unit, start_date: 1.week.ago)
          end
        end
      end

      it 'avoids n+1' do
        expect do
          response, result = post_graphql(id: p1.id) { query }
          expect(response.status).to eq(200), result.inspect
          expect(result.dig('data', 'project', 'unitTypes').length).to eq(20)
        end.to make_database_queries(count: 20..30)
      end
    end

    context 'when user lacks can_view_units permission' do
      before do
        # Create some units to make sure they're not returned
        unit_type = create(:hmis_unit_type, description: 'Test Type')
        create_list(:hmis_unit, 3, project: p1, unit_type: unit_type, user: hmis_user)

        # Remove the permission
        remove_permissions(access_control, :can_view_units)
      end

      it 'returns empty array' do
        response, result = post_graphql(id: p1.id) { query }

        expect(response.status).to eq(200), result.inspect
        unit_types = result.dig('data', 'project', 'unitTypes')
        expect(unit_types).to eq([])
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
