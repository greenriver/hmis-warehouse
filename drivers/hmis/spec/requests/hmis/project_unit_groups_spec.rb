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
  include_context 'hmis base setup'

  let!(:access_control) { create_access_control(hmis_user, ds1) }
  let!(:project) { create :hmis_hud_project, data_source: ds1 }

  before(:each) do
    hmis_login(user)
  end

  let(:query) do
    <<~GRAPHQL
      query GetProjectUnitGroups($id: ID!, $limit: Int = 10, $offset: Int = 0) {
        project(id: $id) {
          id
          unitGroups(limit: $limit, offset: $offset) {
            offset
            limit
            nodesCount
            nodes {
              id
              name
              workflowTemplateIdentifier
              unitType {
                id
                description
              }
              capacity
              availability
              unitTypes {
                id
                unitType
                capacity
                availability
              }
            }
          }
        }
      }
    GRAPHQL
  end

  describe 'GetProjectUnitGroups query' do
    context 'when the project has unit groups' do
      let!(:unit_type) { create :hmis_unit_type, description: '1 Bedroom' }
      let!(:unit_group) do
        group = create(:hmis_unit_group, project: project, name: 'Test Unit Group', unit_type: unit_type)
        3.times { create(:hmis_unit, unit_group: group, project: project, unit_type: unit_type) }
        group
      end

      it 'returns the unit groups for the project with capacity fields' do
        response, result = post_graphql(id: project.id) { query }
        expect(response.status).to eq(200), result.inspect

        unit_groups = result.dig('data', 'project', 'unitGroups', 'nodes')
        expect(unit_groups.length).to eq(1)

        expect(unit_groups.sole).to include(
          'id' => unit_group.id.to_s,
          'name' => unit_group.name,
          'capacity' => 3,
          'availability' => 3,
          'workflowTemplateIdentifier' => unit_group.workflow_template_identifier,
          'unitType' => { 'id' => unit_type.id.to_s, 'description' => unit_type.description },
        )

        # unitTypes array should contain capacity breakdown
        unit_types = unit_groups.sole['unitTypes']
        expect(unit_types.length).to eq(1)
        expect(unit_types.sole).to include(
          'unitType' => '1 Bedroom',
          'capacity' => 3,
          'availability' => 3,
        )
      end
    end

    context 'when there are many unit groups' do
      before do
        20.times do |i|
          unit_type = create(:hmis_unit_type, description: "Type #{i}")
          group = create(:hmis_unit_group, project: project, name: "Group #{i}", unit_type: unit_type)
          # Create some units to test capacity fields
          2.times { create(:hmis_unit, unit_group: group, project: project, unit_type: unit_type) }
        end
      end

      it 'avoids n+1 queries' do
        expect do
          response, result = post_graphql(id: project.id, limit: 50) { query }
          expect(response.status).to eq(200), result.inspect

          unit_groups = result.dig('data', 'project', 'unitGroups', 'nodes')
          expect(unit_groups.length).to eq(20)

          # Verify all unit types are loaded
          unit_groups.each do |unit_group|
            expect(unit_group['unitType']).to be_present
            expect(unit_group['capacity']).to eq(2)
            expect(unit_group['unitTypes'].length).to eq(1)
          end
        end.to make_database_queries(count: 10..20)
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
