###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/graphql_helpers'

RSpec.describe 'PickList CE_ACCESS_POINT_PROJECT_NAMES', type: :request do
  include GraphqlHelpers
  include LoginAndPermissionsSpecHelper

  let!(:ds1) { create(:hmis_primary_data_source) }
  let!(:user) { create(:user) }
  let(:hmis_user) { user.related_hmis_user(ds1) }

  let!(:o1) { create(:hmis_hud_organization, data_source: ds1) } # Visible to current user
  let!(:o2) { create(:hmis_hud_organization, data_source: ds1) } # Not visible to current user
  let!(:access_control) { create_access_control(hmis_user, o1) }

  let(:today) { Date.current }

  # Viewable (o1); open; CE access point Yes; CE status active — should appear in pick list
  let!(:included_access_point_project) { create(:hmis_hud_project, project_name: 'Access Point Yes', organization: o1, data_source: ds1) }
  # Viewable; CE participation exists but AccessPoint is not Yes
  let!(:not_access_point_project) { create(:hmis_hud_project, project_name: 'Not Access Point', organization: o1, data_source: ds1) }
  # Viewable; CE access point Yes but participation status ended before today
  let!(:inactive_ce_status_project) { create(:hmis_hud_project, project_name: 'Inactive CE Status', organization: o1, data_source: ds1) }
  # Viewable; CE access point Yes and active, but project operating period ended before today
  let!(:inactive_project) { create(:hmis_hud_project, project_name: 'Inactive Project', organization: o1, data_source: ds1, operating_end_date: today - 2.weeks) }
  # Same CE setup as included_access_point_project, but org is not in the user’s access
  let!(:unauthorized_project) { create(:hmis_hud_project, project_name: 'Unauthorized Project', organization: o2, data_source: ds1) }

  let!(:included_ce_participation) do
    create(
      :hmis_hud_ce_participation,
      project: included_access_point_project,
      data_source: ds1,
      AccessPoint: 1,
      CEParticipationStatusStartDate: today - 10.years,
      CEParticipationStatusEndDate: nil,
    )
  end

  let!(:not_access_point_ce_participation) do
    create(
      :hmis_hud_ce_participation,
      project: not_access_point_project,
      data_source: ds1,
      AccessPoint: 0,
      CEParticipationStatusStartDate: today - 10.years,
      CEParticipationStatusEndDate: nil,
    )
  end

  let!(:inactive_ce_status_participation) do
    create(
      :hmis_hud_ce_participation,
      project: inactive_ce_status_project,
      data_source: ds1,
      AccessPoint: 1,
      CEParticipationStatusStartDate: today - 10.years,
      CEParticipationStatusEndDate: today - 2.weeks,
    )
  end

  let!(:inactive_operating_ce_participation) do
    create(
      :hmis_hud_ce_participation,
      project: inactive_project,
      data_source: ds1,
      AccessPoint: 1,
      CEParticipationStatusStartDate: today - 10.years,
      CEParticipationStatusEndDate: nil,
    )
  end

  let!(:unauthorized_ce_participation) do
    create(
      :hmis_hud_ce_participation,
      project: unauthorized_project,
      data_source: ds1,
      AccessPoint: 1,
      CEParticipationStatusStartDate: today - 10.years,
      CEParticipationStatusEndDate: nil,
    )
  end

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
  end

  it 'returns only projects that are open, viewable, and have an active CE access-point participation' do
    response, result = post_graphql(pick_list_type: 'CE_ACCESS_POINT_PROJECT_NAMES') { query }
    expect(response.status).to eq(200)

    # Picklist option codes are intentionally project names, NOT ids
    codes = result.dig('data', 'pickList').map { |o| o['code'] }
    expect(codes).to contain_exactly(included_access_point_project.project_name)
    expect(codes).not_to include(not_access_point_project.project_name)
    expect(codes).not_to include(inactive_ce_status_project.project_name)
    expect(codes).not_to include(inactive_project.project_name)
    expect(codes).not_to include(unauthorized_project.project_name)

    # Expect the label to also show project name
    expect(result.dig('data', 'pickList', 0, 'label')).to eq(included_access_point_project.project_name)
  end
end
