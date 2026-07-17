###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/graphql_helpers'

RSpec.describe 'PickList BULK_VOID_CE_PROJECTS', type: :request do
  let!(:ds1) { create(:hmis_primary_data_source) }
  let!(:user) { create(:user) }
  let(:hmis_user) { user.related_hmis_user(ds1) }
  let!(:bulk_void_org) { create(:hmis_hud_organization, data_source: ds1) }

  let!(:editable_ce_project) { create(:hmis_hud_project, data_source: ds1, organization: bulk_void_org, project_type: 14) }
  let!(:viewable_only_ce_project) { create(:hmis_hud_project, data_source: ds1, organization: bulk_void_org, project_type: 14) }
  let!(:closed_ce_project) { create(:hmis_hud_project, data_source: ds1, organization: bulk_void_org, project_type: 14, operating_end_date: 1.week.ago) }
  let!(:non_ce_project) { create(:hmis_hud_project, data_source: ds1, organization: bulk_void_org, project_type: 1) }
  let!(:other_ds) { create(:hmis_data_source) }
  let!(:other_ds_ce_project) { create(:hmis_hud_project, data_source: other_ds, project_type: 14) }

  let(:query) do
    <<~GRAPHQL
      query GetPickList($pickListType: PickListType!) {
        pickList(pickListType: $pickListType) {
          code
          label
          groupLabel
        }
      }
    GRAPHQL
  end

  before do
    create_access_control(hmis_user, bulk_void_org, with_permission: [:can_administrate_coordinated_entry])
    create_access_control(hmis_user, other_ds, with_permission: [:can_administrate_coordinated_entry])

    create_access_control(hmis_user, editable_ce_project, with_permission: [:can_view_project, :can_edit_enrollments])
    create_access_control(hmis_user, viewable_only_ce_project, with_permission: [:can_view_project])
    create_access_control(hmis_user, closed_ce_project, with_permission: [:can_view_project, :can_edit_enrollments])
    create_access_control(hmis_user, non_ce_project, with_permission: [:can_view_project, :can_edit_enrollments])
    create_access_control(hmis_user, other_ds_ce_project, with_permission: [:can_view_project, :can_edit_enrollments])

    hmis_login(user)
    allow_any_instance_of(Hmis::Ce::Configuration).to receive(:bulk_void_enabled?).and_return(true)
  end

  it 'returns open CE projects in the current data source where the user can edit enrollments' do
    response, result = post_graphql(pick_list_type: 'BULK_VOID_CE_PROJECTS') { query }

    expect(response.status).to eq(200), result.inspect
    options = result.dig('data', 'pickList')
    expect(options).to contain_exactly(
      a_hash_including(
        'code' => editable_ce_project.id.to_s,
        'label' => editable_ce_project.project_name,
        'groupLabel' => bulk_void_org.organization_name,
      ),
    )
  end
end
