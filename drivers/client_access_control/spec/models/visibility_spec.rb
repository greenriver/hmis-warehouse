###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe GrdaWarehouse::Hud::Client, type: :model do
  let!(:source_data_source) { create :vt_source_data_source }
  let!(:vt_destination_data_source) { create :vt_destination_data_source }
  let!(:project_coc) { create :vt_project_coc, data_source: source_data_source, CoCCode: 'MA-500' }
  let!(:visible_project) { create :vt_project, ProjectName: 'Visible Project', data_source: source_data_source }
  let!(:visible_enrollment) { create :vt_enrollment, data_source: source_data_source }
  let!(:visible_client) { create :vt_source_client, data_source: source_data_source }
  let!(:destination_client) { create :vt_destination_client, data_source: vt_destination_data_source }
  let!(:warehouse_client) { create :vt_warehouse_client, source_id: visible_client.id, destination_id: destination_client.id }
  let!(:user) { create :vt_user, permission_context: 'acls' }
  let!(:role) { create :vt_role }
  let!(:no_permission_role) { create :role }
  let!(:no_data_source_collection) { create :collection }
  let!(:project_viewable_collection) { create :collection }
  let!(:coc_code_viewable_collection) { create :collection }
  before(:each) do
    project_viewable_collection.add_viewable(visible_project)
  end

  context 'Using visible_to client permission model' do
    describe 'and the user does not have a role' do
      it 'user cannot see any clients' do
        expect(GrdaWarehouse::Hud::Client.source.joins(enrollments: { project: :project_cocs }).count).to eq(1)
        expect(GrdaWarehouse::Hud::Client.destination.count).to eq(1)
        expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(0)
        expect(GrdaWarehouse::Hud::Client.destination_visible_to(user).count).to eq(0)
      end
    end

    describe 'and the user has permission to see full dashboard, but not any data assignments' do
      before do
        role.update(can_view_full_client_dashboard: true)
        setup_access_control(user, role, no_data_source_collection)
      end
      it 'user cannot see any clients' do
        expect(GrdaWarehouse::Hud::Client.source.count).to eq(1)
        expect(GrdaWarehouse::Hud::Client.destination.count).to eq(1)
        expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(0)
        expect(GrdaWarehouse::Hud::Client.destination_visible_to(user).count).to eq(0)
      end
    end

    describe 'and the user has permission to see limited dashboard, but not any data assignments' do
      before do
        role.update(can_view_limited_client_dashboard: true)
        setup_access_control(user, role, no_data_source_collection)
      end
      it 'user cannot see any clients' do
        expect(GrdaWarehouse::Hud::Client.source.count).to eq(1)
        expect(GrdaWarehouse::Hud::Client.destination.count).to eq(1)
        expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(0)
        expect(GrdaWarehouse::Hud::Client.destination_visible_to(user).count).to eq(0)
      end
    end

    describe 'and the user has permission to see clients in wrong CoC, but not any data assignments' do
      before do
        user.user_group_members.destroy_all
        coc_code_viewable_collection.update(coc_codes: ['MA-501'])
        setup_access_control(user, no_permission_role, coc_code_viewable_collection)
        destination_client.update(
          housing_release_status: GrdaWarehouse::Hud::Client.full_release_string,
          consented_coc_codes: ['MA-500'],
        )
      end
      it 'user cannot see any clients' do
        expect(GrdaWarehouse::Hud::Client.source.count).to eq(1)
        expect(GrdaWarehouse::Hud::Client.destination.count).to eq(1)
        expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(0)
        expect(GrdaWarehouse::Hud::Client.destination_visible_to(user).count).to eq(0)
      end
    end

    # Positive test
    describe 'and the user has permission to see full dashboard can see client based on project enrollment' do
      before do
        role.update(can_view_full_client_dashboard: true, can_view_clients: true)
        setup_access_control(user, role, project_viewable_collection)
      end
      it 'user can see one client' do
        expect(GrdaWarehouse::Hud::Client.source.count).to eq(1)
        expect(GrdaWarehouse::Hud::Client.destination.count).to eq(1)
        expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(1)
        expect(GrdaWarehouse::Hud::Client.destination_visible_to(user).count).to eq(1)
      end
    end

    describe 'and the user has permission to see limited dashboard, but not any data assignments' do
      before do
        role.update(can_view_limited_client_dashboard: true)
        setup_access_control(user, role, no_data_source_collection)
      end
      it 'user cannot see any clients' do
        expect(GrdaWarehouse::Hud::Client.source.count).to eq(1)
        expect(GrdaWarehouse::Hud::Client.destination.count).to eq(1)
        expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(0)
        expect(GrdaWarehouse::Hud::Client.destination_visible_to(user).count).to eq(0)
      end
    end

    describe 'and the user has permission to see clients in wrong CoC, but not any data assignments' do
      before do
        user.user_group_members.destroy_all
        coc_code_viewable_collection.update(coc_codes: ['MA-501'])
        setup_access_control(user, no_permission_role, coc_code_viewable_collection)
        destination_client.update(
          housing_release_status: GrdaWarehouse::Hud::Client.full_release_string,
          consented_coc_codes: ['MA-500'],
        )
      end
      it 'user cannot see any clients' do
        expect(GrdaWarehouse::Hud::Client.source.count).to eq(1)
        expect(GrdaWarehouse::Hud::Client.destination.count).to eq(1)
        expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(0)
        expect(GrdaWarehouse::Hud::Client.destination_visible_to(user).count).to eq(0)
      end
    end
  end
end
