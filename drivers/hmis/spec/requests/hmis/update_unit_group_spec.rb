###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe 'UpdateUnitGroup Mutation', type: :request do
  include_context 'hmis base setup'

  subject(:mutation) do
    <<~GRAPHQL
      mutation UpdateUnitGroup($id: ID!, $input: UnitGroupInput!) {
        updateUnitGroup(id: $id, input: $input) {
          unitGroup {
            id
            name
            workflowTemplateIdentifier
            ceEventType
          }
          #{error_fields}
        }
      }
    GRAPHQL
  end

  let!(:access_control) { create_access_control(hmis_user, p1, with_permission: [:can_view_project, :can_manage_units, :can_view_units]) }
  before(:each) { hmis_login(user) }

  let!(:unit_group) { create(:hmis_unit_group, project: p1, name: 'Original Name', workflow_template: nil) }

  let!(:workflow_template) { create(:hmis_workflow_definition_template, data_source: ds1) }
  let(:base_input) do
    {
      id: unit_group.id.to_s,
      input: {
        projectId: p1.id.to_s,
        name: 'Updated Name',
        workflowTemplateIdentifier: workflow_template.identifier,
        ceEventType: 'REFERRAL_TO_PSH_PROJECT_RESOURCE_OPENING',
      },
    }
  end

  it 'updates unit group successfully' do
    response, result = post_graphql(base_input) { mutation }
    expect(response.status).to eq(200), result.inspect
    expect(result.dig('data', 'updateUnitGroup', 'errors')).to be_empty

    updated_group = result.dig('data', 'updateUnitGroup', 'unitGroup')
    expect(updated_group['name']).to eq('Updated Name')
    expect(updated_group['workflowTemplateIdentifier']).to eq(workflow_template.identifier)
    expect(updated_group['ceEventType']).to eq('REFERRAL_TO_PSH_PROJECT_RESOURCE_OPENING')

    unit_group.reload
    expect(unit_group.name).to eq('Updated Name')
    expect(unit_group.workflow_template_identifier).to eq(workflow_template.identifier)
    expect(unit_group.ce_event_type).to eq(14)
  end

  context 'workflow template validation' do
    context 'when workflow template is already set' do
      let(:existing_template) { create(:hmis_workflow_definition_template, data_source: ds1, identifier: 'existing') }
      let(:new_template) { create(:hmis_workflow_definition_template, data_source: ds1, identifier: 'new') }
      let!(:unit_group) { create(:hmis_unit_group, project: p1, name: 'Original Name', workflow_template_identifier: existing_template.identifier) }

      it 'prevents changing to different template' do
        input = base_input.deep_merge(input: { workflowTemplateIdentifier: new_template.identifier })

        response, result = post_graphql(input) { mutation }
        expect(response.status).to eq(200), result.inspect

        errors = result.dig('data', 'updateUnitGroup', 'errors')
        expect(errors).not_to be_empty
        expect(errors.first['fullMessage']).to eq('Workflow template identifier cannot be changed once set')

        unit_group.reload
        expect(unit_group.workflow_template_identifier).to eq(existing_template.identifier)
      end

      it 'prevents clearing template' do
        input = base_input.deep_merge(input: { workflowTemplateIdentifier: nil })

        response, result = post_graphql(input) { mutation }
        expect(response.status).to eq(200), result.inspect

        errors = result.dig('data', 'updateUnitGroup', 'errors')
        expect(errors).not_to be_empty
        expect(errors.first['fullMessage']).to eq('Workflow template identifier cannot be changed once set')

        unit_group.reload
        expect(unit_group.workflow_template_identifier).to eq(existing_template.identifier)
      end
    end

    context 'when workflow template is invalid' do
      let(:other_ds_template) { create(:hmis_workflow_definition_template, identifier: 'other_ds') }

      it 'prevents changing to invalid template' do
        input = base_input.deep_merge(input: { workflowTemplateIdentifier: other_ds_template.identifier })

        response, result = post_graphql(input) { mutation }
        expect(response.status).to eq(200), result.inspect

        errors = result.dig('data', 'updateUnitGroup', 'errors')
        expect(errors).not_to be_empty
        expect(errors.first['fullMessage']).to eq('Workflow template identifier must belong to the same data source')

        unit_group.reload
        expect(unit_group.workflow_template_identifier).to eq(nil)
      end
    end
  end

  context 'name validation' do
    let!(:existing_unit_group) { create(:hmis_unit_group, project: p1, name: 'Existing Group Name') }

    it 'prevents duplicate names within project' do
      input = base_input.deep_merge(input: { name: 'Existing Group Name' })

      response, result = post_graphql(input) { mutation }
      expect(response.status).to eq(200), result.inspect

      errors = result.dig('data', 'updateUnitGroup', 'errors')
      expect(errors).not_to be_empty
      expect(errors.first['fullMessage']).to eq('Name must be unique in the project')

      unit_group.reload
      expect(unit_group.name).to eq('Original Name')
    end
  end

  context 'permissions' do
    before { remove_permissions(access_control, :can_manage_units) }

    it 'requires proper permissions' do
      expect_access_denied post_graphql(base_input) { mutation }
    end
  end
end
