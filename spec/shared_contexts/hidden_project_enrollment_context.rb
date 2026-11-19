###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# One destination client with an HMIS enrollment in a project the user's collection
# includes and one in a project it does not.
RSpec.shared_context 'hidden project enrollment context' do
  let!(:ds) { create(:hmis_data_source) }
  let!(:org) { create(:hmis_hud_organization, data_source: ds) }
  let!(:visible_project) { create(:hmis_hud_project, data_source: ds, organization: org) }
  let!(:hidden_project) { create(:hmis_hud_project, data_source: ds, organization: org) }
  let!(:hmis_client) { create(:hmis_hud_client_with_warehouse_client, data_source: ds) }
  let(:destination) { GrdaWarehouse::WarehouseClient.find_by!(source_id: hmis_client.id).destination }
  let!(:visible_enrollment) { create(:hmis_hud_enrollment, data_source: ds, client: hmis_client, project: visible_project) }
  let!(:hidden_enrollment) { create(:hmis_hud_enrollment, data_source: ds, client: hmis_client, project: hidden_project) }

  let!(:user) { create :acl_user }
  let!(:project_collection) do
    collection = create :collection
    collection.set_viewables({ projects: [visible_project.id] })
    collection
  end
  let(:viewer_role) do
    create(
      :role,
      can_view_clients: true,
      can_view_client_name: true,
      can_search_own_clients: true,
      can_view_enrollment_details: true,
      can_view_limited_client_dashboard: true,
    )
  end
  let(:search_only_role) { create :role, can_view_enrollment_details: true, can_view_client_name: true, can_search_own_clients: true }

  def sign_in_with(role)
    setup_access_control(user, role, project_collection)
    sign_in user
  end
end
