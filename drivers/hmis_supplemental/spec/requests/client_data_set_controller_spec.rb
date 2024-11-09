require 'rails_helper'

RSpec.describe HmisSupplemental::ClientDataSetsController, type: :request do
  let!(:user) { create :acl_user }
  let(:user_group) { create(:user_group) }
  let(:policy) { user.policy_for(destination_client) }
  let(:collection) { create(:collection) }

  let(:data_source) { create :source_data_source }
  let(:source_client) { create :hud_client, data_source: data_source }
  let(:project1) { create :grda_warehouse_hud_project, data_source: data_source }
  let(:project2) { create :grda_warehouse_hud_project, data_source: data_source }
  let!(:enrolment1) { create :hud_enrollment, data_source: data_source, client: source_client, project: project1 }
  let!(:enrolment2) { create :hud_enrollment, data_source: data_source, client: source_client, project: project2 }

  let(:data_source_other) { create :source_data_source }
  let(:source_client_other) { create :hud_client, data_source: data_source_other }
  let(:project_other) { create :grda_warehouse_hud_project, data_source: data_source_other }
  let!(:enrolment_other) { create :hud_enrollment, data_source: data_source_other, client: source_client_other, project: project_other }

  let!(:destination_data_source) { create :destination_data_source }
  let!(:destination_client) { create :hud_client, data_source_id: destination_data_source.id }
  let!(:warehouse_client) { create :warehouse_client, source_id: source_client.id, destination_id: destination_client.id }
  let!(:warehouse_client_other) { create :warehouse_client, source_id: source_client_other.id, destination_id: destination_client.id }
  let(:owner_type) { 'client' }
  let(:data_set) { create(:hmis_supplemental_data_set, owner_type: owner_type, data_source: data_source) }

  let(:role) do
    create(
      :admin_role,
      can_view_supplemental_client_data: true,
    )
  end

  before(:each) do
    create(:access_control, role: role, collection: collection, user_group: user_group)
    collection.set_viewables({ supplemental_data_sets: [data_set.id], data_sources: [data_source.id], projects: [project1.id, project2.id, project_other.id] })
    sign_in(user)
  end

  context 'with access' do
    before(:each) do
      user_group.add(user)
    end

    it 'resolves one group for the client' do
      get hmis_supplemental_data_set_client_data_set_path(data_set, destination_client)

      expect(response).to be_successful
      expect(assigns(:groups)).to be_an(Array)
      expect(assigns(:groups).first[:title]).to eq(data_source.name)
      expect(assigns(:groups).size).to eq(1)
    end

    context 'with enrollment data set' do
      let(:owner_type) { 'enrollment' }

      it 'resolves one group for each enrollment' do
        get hmis_supplemental_data_set_client_data_set_path(data_set, destination_client)

        expect(response).to be_successful
        expect(assigns(:groups)).to be_an(Array)
        expect(assigns(:groups).map { |h| h[:title] }).to include(
          a_string_including(project1.name),
          a_string_including(project2.name),
        )
        expect(assigns(:groups).size).to eq(2)
      end
    end
  end

  context 'without access' do
    it 'denies access' do
      get hmis_supplemental_data_set_client_data_set_path(data_set, destination_client)
      expect(response).to redirect_to(root_path)
    end
  end
end
