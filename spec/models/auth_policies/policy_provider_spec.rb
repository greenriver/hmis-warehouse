require 'rails_helper'

RSpec.describe 'GrdaWarehouse::AuthPolicies::PolicyProvider', type: :model do
  let!(:data_source) { create :data_source_fixed_id }
  let!(:authorized_organization) { create :hud_organization, data_source: data_source }
  let(:authorized_project) { create :grda_warehouse_hud_project, organization: authorized_organization }
  let(:authorized_client) do
    client = create(:hud_client, data_source: data_source)
    create :hud_enrollment, client: client, data_source: data_source, project: authorized_project
    client
  end
  let!(:restricted_data_source) { create :grda_warehouse_data_source }
  let(:restricted_project) { create :grda_warehouse_hud_project, data_source: restricted_data_source }
  let(:restricted_client) do
    client = create(:hud_client, data_source: restricted_data_source)
    create :hud_enrollment, client: client, data_source: restricted_data_source, project: restricted_project
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
  describe 'with legacy user permissions' do
    let(:access_group) { create(:access_group) }
    let(:user) do
      user = create :user
      role.add(user)
      access_group.add(user)
      user
    end

    context 'with access to a project' do
      before(:each) do
        access_group.add_viewable(authorized_project)
      end
      it 'allows access to authorized project' do
        check_permissions(policy: user.policies.for_project(authorized_project), role: role)
      end
      it 'allows access to authorized client' do
        check_permissions(policy: user.policies.for_client(authorized_client), role: role)
      end
    end

    context 'without access to a project' do
      it 'denies access to restricted project' do
        check_permissions(policy: user.policies.for_project(authorized_project), role: nil)
      end
      it 'denies access to restricted client' do
        check_permissions(policy: user.policies.for_client(authorized_client), role: nil)
      end
    end
  end
  # END_ACL

  describe 'with user access control permissions' do
    let(:user) { create :acl_user }

    def create_authorized_collection(user:, role:)
      user_group = create(:user_group)
      user_group.add(user)
      collection = create(:collection)
      create :access_control, role: role, collection: collection, user_group: user_group
      collection
    end

    shared_examples 'expect authorized access' do
      it 'allows access to authorized project' do
        check_permissions(policy: user.policies.for_project(authorized_project), role: role)
      end
      it 'allows access to authorized client' do
        check_permissions(policy: user.policies.for_client(authorized_client), role: role)
      end
    end

    shared_examples 'expect restricted access' do
      it 'denies access to restricted project' do
        check_permissions(policy: user.policies.for_project(restricted_project), role: nil)
      end
      it 'denies access to restricted client' do
        check_permissions(policy: user.policies.for_client(restricted_client), role: nil)
      end
    end

    context 'with an authorized project' do
      before(:each) do
        collection = create_authorized_collection(user: user, role: role)
        collection.set_viewables({ projects: [authorized_project.id] })
      end
      include_examples 'expect authorized access'
      include_examples 'expect restricted access'
    end

    context 'with an authorized organization' do
      before(:each) do
        collection = create_authorized_collection(user: user, role: role)
        collection.set_viewables({ organizations: [authorized_project.organization.id] })
      end
      include_examples 'expect authorized access'
      include_examples 'expect restricted access'
    end

    context 'with an authorized data source' do
      before(:each) do
        collection = create_authorized_collection(user: user, role: role)
        collection.set_viewables({ data_sources: [authorized_project.data_source.id] })
      end
      include_examples 'expect authorized access'
      include_examples 'expect restricted access'
    end

    context 'with an authorized project group' do
      let(:authorized_project_group) do
        group = create(:project_access_group)
        authorized_project.project_groups << group
        authorized_project.save!
        group
      end
      before(:each) do
        collection = create_authorized_collection(user: user, role: role)
        collection.set_viewables({ project_groups: [authorized_project_group.id] })
      end
      include_examples 'expect authorized access'
      include_examples 'expect restricted access'
    end

    context 'with an authorized CoC code' do
      let(:authorized_coc_code) { 'authtest1' }
      let!(:authorized_coc) do
        authorized_project.project_cocs.create!(coc_code: authorized_coc_code)
      end

      before(:each) do
        collection = create_authorized_collection(user: user, role: role)
        collection.update!(coc_codes: [authorized_coc_code])
      end
      include_examples 'expect authorized access'
      include_examples 'expect restricted access'
    end

    context 'with system group access' do
      before(:each) do
        user_group = create(:user_group)
        user_group.add(user)
        collection = Collection.system_collection(:data_sources)
        create :access_control, role: role, collection: collection, user_group: user_group
      end
      include_examples 'expect authorized access'

      it 'allows access to restricted projects' do
        check_permissions(policy: user.policies.for_project(restricted_project), role: role)
        check_permissions(policy: user.policies.for_client(restricted_client), role: role)
      end
    end

    it 'denies access' do
      check_permissions(policy: user.policies.for_project(authorized_project), role: nil)
      check_permissions(policy: user.policies.for_client(authorized_client), role: nil)
    end
  end
end
