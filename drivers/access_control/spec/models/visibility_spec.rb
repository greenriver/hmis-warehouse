require 'rails_helper'

RSpec.describe GrdaWarehouse::Hud::Client, type: :model do
  let!(:source_data_source) { create :vt_source_data_source }
  let!(:vt_destination_data_source) { create :vt_destination_data_source }
  let!(:project_coc) { create :vt_project_coc, data_source: source_data_source }
  let!(:visible_project) { create :vt_project, ProjectName: 'Visible Project', data_source: source_data_source }
  let!(:visible_enrollment) { create :vt_enrollment, data_source: source_data_source }
  let!(:visible_client) { create :vt_source_client, data_source: source_data_source }
  let!(:destination_client) { create :vt_destination_client, data_source: vt_destination_data_source }
  let!(:warehouse_client) { create :vt_warehouse_client, source_id: visible_client.id, destination_id: destination_client.id }
  let!(:user) { create :vt_user }
  let!(:role) { create :vt_role }
  # can_view_limited_client_dashboard
  context 'Using visible_to client permission model' do
    describe 'and the user does not have a role' do
      it 'user cannot see any clients' do
        expect(GrdaWarehouse::Hud::Client.source.joins(enrollments: { project: :project_cocs }).count).to eq(1)
        expect(GrdaWarehouse::Hud::Client.destination.count).to eq(1)
        expect(GrdaWarehouse::Hud::Client.source_visible_to(user).count).to eq(0)
        expect(GrdaWarehouse::Hud::Client.destination_visible_to(user).count).to eq(0)
      end
    end

    describe 'and the user has permission to see clients, but not any data assignments' do
      before do
        role.update(can_view_full_client_dashboard: true)
        user.roles = [role]
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
