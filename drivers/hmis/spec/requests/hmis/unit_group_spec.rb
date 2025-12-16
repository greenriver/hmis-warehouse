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
      query GetUnitGroup($id: ID!) {
        unitGroup(id: $id) {
          id
          name
          capacity
          availability
          unitTypes {
            id
            unitType
            capacity
            availability
          }
          workflowTemplateName
          ceEventType
          workflowTemplateIdentifier
          directReferralWorkflowTemplateName
          directReferralWorkflowTemplateIdentifier
          eligibilityRequirements {
            id
            name
            ownerType
            expression
            projectTypes
            funders
          }
          prioritySchemes {
            id
            name
            ownerType
            expression
          }
          unitType {
            id
            description
          }
        }
      }
    GRAPHQL
  end

  describe 'GetUnitGroup query' do
    let!(:unit_type) { create :hmis_unit_type, description: '2 Bedroom' }
    let!(:unit_group) do
      group = create(:hmis_unit_group, project: project, name: 'Test Unit Group', unit_type: unit_type)
      5.times { create(:hmis_unit, unit_group: group, project: project, unit_type: unit_type) }
      group
    end
    let!(:eligibility_requirement) do
      create :hmis_ce_eligibility_requirement,
             owner: unit_group,
             name: 'Age Requirement',
             expression: 'current_age >= 18',
             applicability_config: { 'project_types' => [1] }
    end
    let!(:priority_scheme) do
      create :hmis_ce_priority_scheme,
             owner: unit_group,
             name: 'Days Homeless',
             expression: 'days_homeless'
    end

    it 'returns the unit group with all detail fields' do
      response, result = post_graphql(id: unit_group.id) { query }
      expect(response.status).to eq(200), result.inspect

      unit_group_data = result.dig('data', 'unitGroup')

      # Basic fields
      expect(unit_group_data).to include(
        'id' => unit_group.id.to_s,
        'name' => unit_group.name,
        'capacity' => 5,
        'availability' => 5,
        'workflowTemplateIdentifier' => unit_group.workflow_template_identifier,
        'workflowTemplateName' => unit_group.workflow_template.name,
        'unitType' => { 'id' => unit_type.id.to_s, 'description' => unit_type.description },
      )

      # unitTypes capacity breakdown
      unit_types = unit_group_data['unitTypes']
      expect(unit_types.length).to eq(1)
      expect(unit_types.sole).to include(
        'unitType' => '2 Bedroom',
        'capacity' => 5,
        'availability' => 5,
      )

      # CE match rules
      eligibility_requirements = unit_group_data['eligibilityRequirements']
      expect(eligibility_requirements.length).to eq(1)
      expect(eligibility_requirements.sole).to include(
        'id' => eligibility_requirement.id.to_s,
        'name' => 'Age Requirement',
        'ownerType' => 'UNIT_GROUP',
        'expression' => 'current_age >= 18',
        'projectTypes' => ['ES_NBN'],
      )

      priority_schemes = unit_group_data['prioritySchemes']
      expect(priority_schemes.length).to eq(1)
      expect(priority_schemes.sole).to include(
        'id' => priority_scheme.id.to_s,
        'name' => 'Days Homeless',
        'expression' => 'days_homeless',
      )
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
