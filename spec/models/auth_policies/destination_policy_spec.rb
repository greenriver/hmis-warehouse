require 'rails_helper'

RSpec.describe GrdaWarehouse::AuthPolicies::DestinationClientPolicy, type: :model do
  let(:data_source) { create :data_source_fixed_id }
  let(:project) { create :grda_warehouse_hud_project, data_source: data_source }
  let(:source_client) { create :hud_client, data_source: data_source }
  let!(:enrollment) { create :hud_enrollment, client: source_client, project: project }

  let!(:destination_data_source) { create :destination_data_source }
  let!(:destination_client) { create :hud_client, data_source_id: destination_data_source.id }
  let!(:warehouse_client) { create :warehouse_client, source_id: source_client.id, destination_id: destination_client.id }

  let(:role) do
    create(:role,
           can_view_clients: true,
           can_view_client_name: true,
           can_view_client_photo: true,
           can_view_full_dob: true,
           can_view_full_ssn: false,
           can_view_hiv_status: false)
  end

  context 'with legacy user permissions' do
    let(:access_group) { create(:access_group) }
    let(:user) do
      user = create(:user)
      role.add(user)
      access_group.add(user)
      user
    end
    let(:policy) { user.policy_for(destination_client) }

    before do
      access_group.add_viewable(project)
    end

    it 'delegates permissions to source client policy' do
      expect(policy.can_view?).to be true
      expect(policy.can_view_name?).to be true
      expect(policy.can_view_photo?).to be true
      expect(policy.can_view_full_dob?).to be true
      expect(policy.can_view_full_ssn?).to be false
      expect(policy.can_view_hiv_status?).to be false
    end
  end

  context 'with user access control permissions' do
    let(:user) { create(:acl_user) }
    let(:user_group) { create(:user_group) }
    let(:collection) { create(:collection) }
    let(:policy) { user.policy_for(destination_client) }

    before do
      user_group.add(user)
      create(:access_control, role: role, collection: collection, user_group: user_group)
      collection.set_viewables({ projects: [project.id] })
    end

    it 'delegates permissions to source client policy' do
      expect(policy.can_view?).to be true
      expect(policy.can_view_name?).to be true
      expect(policy.can_view_photo?).to be true
      expect(policy.can_view_full_dob?).to be true
      expect(policy.can_view_full_ssn?).to be false
      expect(policy.can_view_hiv_status?).to be false
    end
  end
end
