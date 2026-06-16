###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/graphql_helpers'

RSpec.describe 'PickList OPEN_ORGANIZATION_NAMES', type: :request do
  include GraphqlHelpers
  include LoginAndPermissionsSpecHelper

  let!(:ds1) { create(:hmis_primary_data_source) }
  let!(:ds2) { create(:hmis_data_source) }
  let!(:user) { create(:user) }
  let(:hmis_user) { user.related_hmis_user(ds1) }

  let!(:o1) { create(:hmis_hud_organization, data_source: ds1, organization_name: 'Visible Org') }
  let!(:o2) { create(:hmis_hud_organization, data_source: ds1, organization_name: 'Unauthorized Org') }
  let!(:o3) { create(:hmis_hud_organization, data_source: ds1, organization_name: 'Visible Closed Org') }
  let!(:o4) { create(:hmis_hud_organization, data_source: ds2, organization_name: 'Visible Other DS Org') }

  let(:today) { Date.current }

  let!(:open_project_o1) { create(:hmis_hud_project, organization: o1, data_source: ds1) }
  let!(:open_project_o2) { create(:hmis_hud_project, organization: o2, data_source: ds1) }
  let!(:closed_project_o3) do
    create(:hmis_hud_project, organization: o3, data_source: ds1, operating_end_date: today - 2.weeks)
  end
  let!(:open_project_o4) { create(:hmis_hud_project, organization: o4, data_source: ds2) }

  let(:query) do
    <<~GRAPHQL
      query GetPickList($pickListType: PickListType!) {
        pickList(pickListType: $pickListType) {
          code
          label
        }
      }
    GRAPHQL
  end

  before do
    hmis_login(user)

    # grant full access to o1, o3, and o4
    create_access_control(hmis_user, o1)
    create_access_control(hmis_user, o3)
    create_access_control(hmis_user, o4)
  end

  it 'returns viewable organizations in the current data source that have open projects' do
    response, result = post_graphql(pick_list_type: 'OPEN_ORGANIZATION_NAMES') { query }
    expect(response.status).to eq(200)

    pick_list = result.dig('data', 'pickList')
    codes = pick_list.map { |o| o['code'] }

    # o1: viewable and has an open project
    # o2: has an open project but is not viewable to the user
    # o3: viewable but only has closed projects
    # o4: viewable but in different data source
    expect(codes).to contain_exactly("#{o1.organization_name} (#{o1.id})")

    expect(pick_list.first['label']).to eq(o1.organization_name)
  end
end
