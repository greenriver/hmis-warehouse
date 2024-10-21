###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

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
  let(:unit_type) { create(:hmis_unit_type) }

  before(:each) do
    hmis_login(user)
  end

  it 'creates units' do
    input = { input: { input: { projectId: p1.id.to_s, count: 1, unitTypeId: unit_type.id } } }
    versions = GrdaWarehouse.paper_trail_versions.where(project_id: p1.id, item_type: 'Hmis::Unit')
    units = Hmis::Unit.where(unit_type: unit_type, project: p1)
    expect do
      response, = post_graphql(input) { mutation }
      expect(response.status).to eq 200
    end.to change(versions, :count).by(1).
      and change(units, :count).by(1)
  end
end
