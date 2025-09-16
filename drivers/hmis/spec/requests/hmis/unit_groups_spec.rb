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
  let!(:unit_group) do
    group = create(:hmis_unit_group, project: project, name: 'Test Unit Group')
    10.times { create(:hmis_unit, unit_group: group, project: project) }
    group
  end
  let!(:eligibility_requirement) { create :hmis_ce_eligibility_requirement, owner: unit_group, applicability_config: { 'project_types' => [1] } }

  before(:each) do
    hmis_login(user)
  end

  let(:query) do
    <<~GRAPHQL
      query GetProjectUnitGroups($id: ID!) {
        project(id: $id) {
          id
          unitGroups {
            nodes {
              id
              name
              eligibilityRequirements {
                id
                name
                ownerType
                expression
                projectTypes
                funders
              }
              workflowTemplateIdentifier
              workflowTemplateName
              units {
                nodesCount
              }
            }
          }
        }
      }
    GRAPHQL
  end

  describe 'get unitGroups query' do
    context 'when the project has unit groups' do
      it 'returns the unit groups for the project' do
        response, result = post_graphql(id: project.id) { query }
        expect(response.status).to eq(200), result.inspect
        unit_groups = result.dig('data', 'project', 'unitGroups', 'nodes')
        expect(unit_groups.length).to eq(1)
        expect(unit_groups.first).to match(
          {
            'id' => unit_group.id.to_s,
            'name' => unit_group.name,
            'eligibilityRequirements' => [
              a_hash_including(
                'id' => eligibility_requirement.id.to_s,
                'ownerType' => 'UNIT_GROUP',
                'projectTypes' => ['ES_NBN'],
              ),
            ],
            'units' => { 'nodesCount' => 10 },
            'workflowTemplateIdentifier' => unit_group.workflow_template_identifier,
            'workflowTemplateName' => unit_group.workflow_template.name,
          },
        )
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
