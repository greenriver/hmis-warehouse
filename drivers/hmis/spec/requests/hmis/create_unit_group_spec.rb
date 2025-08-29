###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe 'CreateUnitGroup Mutation', type: :request do
  include_context 'hmis base setup'

  subject(:mutation) do
    <<~GRAPHQL
      mutation CreateUnitGroup($input: UnitGroupInput!) {
        createUnitGroup(input: $input) {
          unitGroup {
            id
            name
            workflowTemplateIdentifier
            ceEventType
            unitType {
              id
              description
            }
          }
          #{error_fields}
        }
      }
    GRAPHQL
  end

  let!(:access_control) { create_access_control(hmis_user, p1, with_permission: [:can_view_project, :can_manage_units, :can_view_units]) }
  let!(:workflow_template) { create(:hmis_workflow_definition_template, data_source: ds1) }
  let!(:unit_type) { create(:hmis_unit_type, description: 'Studio Apartment') }

  before(:each) { hmis_login(user) }

  let(:base_input) do
    {
      input: {
        projectId: p1.id.to_s,
        name: 'New Unit Group',
        workflowTemplateIdentifier: workflow_template.identifier,
        ceEventType: 'REFERRAL_TO_PSH_PROJECT_RESOURCE_OPENING',
        unitTypeId: unit_type.id.to_s,
      },
    }
  end

  it 'creates unit group successfully' do
    response, result = post_graphql(base_input) { mutation }
    expect(response.status).to eq(200), result.inspect
    expect(result.dig('data', 'createUnitGroup', 'errors')).to be_empty

    created_group = result.dig('data', 'createUnitGroup', 'unitGroup')
    expect(created_group['name']).to eq('New Unit Group')
    expect(created_group['workflowTemplateIdentifier']).to eq(workflow_template.identifier)
    expect(created_group['ceEventType']).to eq('REFERRAL_TO_PSH_PROJECT_RESOURCE_OPENING')
    expect(created_group['unitType']['id']).to eq(unit_type.id.to_s)
    expect(created_group['unitType']['description']).to eq('Studio Apartment')

    # Verify the unit group was actually created in the database
    unit_group = Hmis::UnitGroup.find(created_group['id'])
    expect(unit_group.name).to eq('New Unit Group')
    expect(unit_group.project_id).to eq(p1.id)
    expect(unit_group.workflow_template_identifier).to eq(workflow_template.identifier)
    expect(unit_group.ce_event_type).to eq(14)
    expect(unit_group.unit_type_id).to eq(unit_type.id)
  end

  context 'when name is missing' do
    let(:input_without_name) { base_input.deep_merge(input: { name: nil }) }

    it 'returns validation error' do
      response, result = post_graphql(input_without_name) { mutation }
      expect(response.status).to eq(200), result.inspect

      errors = result.dig('data', 'createUnitGroup', 'errors')
      expect(errors).not_to be_empty
      expect(errors.first['attribute']).to eq('name')
      expect(errors.first['type']).to eq('required')
    end
  end

  context 'when name is not unique within project' do
    let!(:existing_unit_group) { create(:hmis_unit_group, project: p1, name: 'Existing Group Name') }
    let(:input_with_duplicate_name) { base_input.deep_merge(input: { name: 'Existing Group Name' }) }

    it 'returns validation error' do
      response, result = post_graphql(input_with_duplicate_name) { mutation }
      expect(response.status).to eq(200), result.inspect

      errors = result.dig('data', 'createUnitGroup', 'errors')
      expect(errors).not_to be_empty
      expect(errors.first['fullMessage']).to eq('Name must be unique in the project')
    end
  end

  context 'when unit type is missing' do
    let(:input_without_unit_type) { base_input.deep_merge(input: { unitTypeId: nil }) }

    it 'returns validation error' do
      response, result = post_graphql(input_without_unit_type) { mutation }
      expect(response.status).to eq(200), result.inspect

      errors = result.dig('data', 'createUnitGroup', 'errors')
      expect(errors).not_to be_empty
      expect(errors.first['attribute']).to eq('unitTypeId')
      expect(errors.first['type']).to eq('required')
    end
  end

  context 'when project has restricted unit types' do
    let!(:restricted_unit_type) { create(:hmis_unit_type, description: 'Restricted Type') }
    let!(:project_mapping) { create(:project_unit_type_mapping, project: p1, unit_type: unit_type) }

    it 'succeeds with allowed unit type' do
      response, result = post_graphql(base_input) { mutation }
      expect(response.status).to eq(200), result.inspect
      expect(result.dig('data', 'createUnitGroup', 'errors')).to be_empty
      created_group = result.dig('data', 'createUnitGroup', 'unitGroup')
      expect(created_group['unitType']['id']).to eq(unit_type.id.to_s)
    end

    it 'returns validation error with incorrect unit type' do
      input = base_input.deep_merge(input: { unitTypeId: restricted_unit_type.id })
      response, result = post_graphql(input) { mutation }
      expect(response.status).to eq(200), result.inspect

      errors = result.dig('data', 'createUnitGroup', 'errors')
      expect(errors).not_to be_empty
      expect(errors.first['attribute']).to eq('unitTypeId')
      expect(errors.first['type']).to eq('invalid')
    end
  end

  context 'permissions' do
    context 'when user lacks manage_units permission' do
      before { remove_permissions(access_control, :can_manage_units) }

      it 'returns access denied' do
        expect_access_denied post_graphql(base_input) { mutation }
      end
    end
  end
end
