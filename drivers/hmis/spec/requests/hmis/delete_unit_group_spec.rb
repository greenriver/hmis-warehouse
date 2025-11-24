###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe 'DeleteUnitGroup Mutation', type: :request do
  include_context 'hmis base setup'

  subject(:mutation) do
    <<~GRAPHQL
      mutation DeleteUnitGroup($id: ID!) {
        deleteUnitGroup(id: $id) {
          unitGroup {
            id
            name
          }
          #{error_fields}
        }
      }
    GRAPHQL
  end

  let!(:access_control) { create_access_control(hmis_user, p1, with_permission: [:can_view_project, :can_manage_units, :can_view_units]) }
  let!(:unit_group) { create(:hmis_unit_group, project: p1) }

  before(:each) { hmis_login(user) }

  let(:input) { { id: unit_group.id.to_s } }

  context 'when unit group has no units' do
    let!(:rule) { create(:hmis_ce_eligibility_requirement, owner: unit_group) }

    it 'deletes unit group successfully' do
      expect do
        response, result = post_graphql(input) { mutation }
        expect(response.status).to eq(200), result.inspect
        expect(result.dig('data', 'deleteUnitGroup', 'errors')).to be_empty
        unit_group.reload
      end.to change(Hmis::UnitGroup, :count).by(-1).
        and change(Hmis::Ce::Match::Rule, :count).by(-1). # deletes rules owned by this unit group
        and change(unit_group, :deleted_at).from(nil)
    end
  end

  context 'when unit group has units' do
    let!(:unit) { create(:hmis_unit, project: p1, unit_group: unit_group) }

    it 'returns validation error' do
      expect do
        response, result = post_graphql(input) { mutation }
        expect(response.status).to eq(200), result.inspect

        errors = result.dig('data', 'deleteUnitGroup', 'errors')
        expect(errors).not_to be_empty
        expect(errors.first['fullMessage']).to eq('Cannot delete unit group with existing units')
      end.to not_change(Hmis::UnitGroup, :count).
        and not_change(unit_group.reload, :deleted_at)
    end
  end

  describe 'permissions' do
    context 'when user lacks manage_units permission' do
      # (even if they have can_update_unit_availability, a more restricted permission)
      let!(:access_control) { create_access_control(hmis_user, p1, with_permission: [:can_view_project, :can_view_units, :can_update_unit_availability]) }

      it 'returns access denied' do
        expect_access_denied post_graphql(input) { mutation }
      end
    end
  end
end
