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
  let!(:unit_type) { create(:hmis_unit_type, description: '2 bedroom') }
  let!(:unit_group) { create(:hmis_unit_group, project: p1, unit_type: unit_type) }

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
    end.to change(versions, :count).by(1).
      and change(units, :count).by(1)

    expect(units.pluck(:unit_type_id).uniq.sole).to eq(unit_type.id)
  end
end
