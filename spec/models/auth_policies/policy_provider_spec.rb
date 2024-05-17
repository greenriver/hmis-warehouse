require 'rails_helper'

RSpec.describe 'GrdaWarehouse::AuthPolicies::PolicyProvider', type: :model do
  let!(:data_source) { create :data_source_fixed_id }
  let(:authorized_project) { create :grda_warehouse_hud_project }
  let(:authorized_client) do
    client = create(:hud_client, data_source: data_source)
    create :hud_enrollment, client: client, data_source: data_source, project: authorized_project
    client
  end
  let(:restricted_project) { create :grda_warehouse_hud_project }
  let(:restricted_client) do
    client = create(:hud_client, data_source: data_source)
    create :hud_enrollment, client: client, data_source: data_source, project: restricted_project
    client
  end

  let(:permissions) do
    {
      can_view_projects: true,
      can_view_clients: true,
      can_view_full_ssn: false,
      can_view_full_dob: true,
      can_view_hiv_status: nil,
    }
  end

  let(:role) do
    create(:role, **permissions.compact_blank)
  end

  def check_permissions(policy:, role:)
    permissions.keys.each do |permission|
      actual = policy.send("#{permission}?")
      expected = role ? role.send(permission) : false
      expect(actual).to eq(expected), "#{permission}: #{actual} != #{expected}"
    end
  end

  # TODO: START_ACL remove after ACL migration is complete
  describe 'with legacy permissions' do
    let(:user) do
      user = create :user
      user
    end

    def legacy_grant_user_project_access(user:, project:, role:)
      access_group = create(:access_group)
      access_group.add(user)
      access_group.add_viewable(project)
      role.add(user)
    end

    context 'with implicit authorization' do
      before(:each) do
        user.policies.legacy_implicitly_assume_authorized_access = true
      end

      context 'with access to a project' do
        before(:each) do
          legacy_grant_user_project_access(user: user, project: authorized_project, role: role)
        end
        it 'has expected project policy' do
          check_permissions(policy: user.policies.for_project(authorized_project), role: role)
        end
        it 'has expected client policy' do
          check_permissions(policy: user.policies.for_client(authorized_client), role: role)
        end
      end

      context 'with access to a project' do
        it 'has expected project policy' do
          check_permissions(policy: user.policies.for_project(authorized_project), role: nil)
        end
        it 'has expected client policy' do
          check_permissions(policy: user.policies.for_client(authorized_client), role: nil)
        end
      end
    end

    it 'raises on attempt to use global policy' do
      expect do
        check_permissions(policy: user.policies.for_project(authorized_project), role: nil)
      end.to raise_error
      expect do
        check_permissions(policy: user.policies.for_client(authorized_client), role: nil)
      end.to raise_error
    end
  end
  # END_ACL

  describe 'with access control permissions' do
    let(:user) { create :acl_user }

    def grant_user_project_access(user:, project:, role:)
      user_group = create(:user_group)
      user_group.add(user)
      collection = create(:collection)
      collection.set_viewables({ projects: [project.id] })
      create :access_control, role: role, collection: collection, user_group: user_group
    end

    context 'with access to a project' do
      before(:each) do
        grant_user_project_access(user: user, project: authorized_project, role: role)
      end

      it 'has expected in-group project policy' do
        check_permissions(policy: user.policies.for_project(authorized_project), role: role)
        check_permissions(policy: user.policies.for_project(restricted_project), role: nil)
      end
      it 'has expected in-group client policy' do
        check_permissions(policy: user.policies.for_client(authorized_client), role: role)
        check_permissions(policy: user.policies.for_client(restricted_client), role: nil)
      end
    end

    it 'has expected project policy' do
      check_permissions(policy: user.policies.for_project(authorized_project), role: nil)
    end
    it 'has expected client policy' do
      check_permissions(policy: user.policies.for_client(authorized_client), role: nil)
    end
  end
end
