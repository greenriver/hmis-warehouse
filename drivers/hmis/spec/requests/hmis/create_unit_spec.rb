###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe 'Create Units Mutation', type: :request do
  include_context 'hmis base setup'

  subject(:mutation) do
    <<~GRAPHQL
      mutation CreateUnits($input: CreateUnitsInput!) {
        createUnits(input: $input) {
          units {
            id
          }
          #{error_fields}
        }
      }
    GRAPHQL
  end

  let!(:access_control) { create_access_control(hmis_user, p1, with_permission: [:can_view_project, :can_manage_units, :can_view_units]) }
  let(:unit_type) { create(:hmis_unit_type, description: '2 bedroom') }
  let(:unit_group) { create(:hmis_unit_group, project: p1, unit_type: nil) }

  before(:each) do
    hmis_login(user)
  end

  let(:input) do
    {
      input: {
        input: {
          projectId: p1.id.to_s,
          count: 1,
          unitGroupId: unit_group.id,
          unitTypeId: unit_type.id,
        },
      },
    }
  end

  it 'creates units' do
    versions = GrdaWarehouse.paper_trail_versions.where(project_id: p1.id, item_type: 'Hmis::Unit')
    units = Hmis::Unit.where(hmis_unit_group_id: unit_group.id)
    expect do
      response, result = post_graphql(input) { mutation }
      expect(response.status).to eq(200), result.inspect
      unit_group.reload
    end.to change(versions, :count).by(1).
      and change(units, :count).by(1).
      and change(unit_group, :unit_type).from(nil).to(unit_type)
  end

  context 'when unit type is not provided' do
    let(:input) do
      {
        input: {
          input: {
            projectId: p1.id.to_s,
            count: 1,
            unitGroupId: unit_group.id,
          },
        },
      }
    end

    it 'raises an error' do
      response, result = post_graphql(input) { mutation }
      expect(response.status).to eq(200), result.inspect

      errors = result.dig('data', 'createUnits', 'errors')
      expect(errors).not_to be_empty
      expect(errors.first['attribute']).to eq('unitTypeId')
      expect(errors.first['type']).to eq('required')
    end
  end

  context 'when unit group already has a unit type' do
    let(:existing_unit_type) { create(:hmis_unit_type, description: '1 bedroom') }

    shared_examples 'returns unit type consistency error' do
      it 'raises an error' do
        response, result = post_graphql(input) { mutation }
        expect(response.status).to eq(200), result.inspect

        errors = result.dig('data', 'createUnits', 'errors')
        expect(errors).not_to be_empty
        expect(errors.first['attribute']).to eq('unitTypeId')
        expect(errors.first['type']).to eq('invalid')
        expect(errors.first['message']).to eq("must be consistent with unit group's existing type")
      end
    end

    context 'unit type is directly associated with unit group' do
      let(:unit_group) { create(:hmis_unit_group, project: p1, unit_type: existing_unit_type) }

      include_examples 'returns unit type consistency error'
    end

    context 'no direct association, but existing units in the group have that type' do
      let!(:existing_unit) { create(:hmis_unit, unit_type: existing_unit_type, unit_group: unit_group) }

      include_examples 'returns unit type consistency error'
    end
  end
end
