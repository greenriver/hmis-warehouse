###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe 'Delete units mutation', type: :request do
  include_context 'hmis base setup'

  subject(:mutation) do
    <<~GRAPHQL
      mutation DeleteUnits($input: DeleteUnitsInput!) {
        deleteUnits(input: $input) {
          unitIds
          #{error_fields}
        }
      }
    GRAPHQL
  end

  let!(:access_control) { create_access_control(hmis_user, p1, with_permission: [:can_view_project, :can_manage_units, :can_view_units]) }
  let(:unit) { create(:hmis_unit, project: p1) }

  before(:each) do
    hmis_login(user)
  end

  it 'deletes units' do
    input = { input: { unitIds: [unit.id.to_s] } }
    versions = unit.versions.where(project_id: p1.id)
    units = Hmis::Unit.where(id: unit.id)
    expect do
      response, = post_graphql(input) { mutation }
      expect(response.status).to eq 200
    end.to change(versions, :count).by(1).
      and change(units, :count).by(-1)
  end
end
