require 'rails_helper'

RSpec.describe GrdaWarehouse::AuthPolicies::ProjectPolicy, type: :model do
  let(:data_source) { create :data_source_fixed_id }
  let(:organization) { create :hud_organization, data_source: data_source }
  let(:project) { create :grda_warehouse_hud_project, organization: organization }

  # Permissions that will be granted through the role
  let(:permissions) do
    {
      can_edit_projects: false,
      can_delete_projects: false,
      can_view_projects: true,
      can_view_imports: false,
      can_view_clients: true,
      can_view_project_locations: false,
      can_view_confidential_project_names: true,
    }
  end

  let(:role) { create(:role, **permissions.compact_blank) }

  shared_examples 'permission checks' do |role_present|
    it 'handles basic permissions appropriately' do
      [
        [:can_edit?, false],
        [:can_delete?, false],
        [:can_view?, true],
        [:can_view_imports?, false],
        [:can_view_clients?, true],
        [:can_view_project_locations?, false],
      ].each do |method, expected|
        expected = role_present ? expected : false
        actual = policy.send(method)
        expect(actual).to eq(expected), "#{method}: #{actual} != #{expected}"
      end
    end

    context 'project name visibility' do
      context 'with non-confidential project' do
        it 'allows viewing project name' do
          expected = role_present
          expect(policy.can_view_name?).to eq(expected)
        end
      end

      context 'with confidential project' do
        it 'respects confidential project name permissions' do
          project.update!(confidential: true)
          expected = role_present && permissions[:can_view_confidential_project_names]
          expect(policy.can_view_name?).to eq(expected)
        end
      end
    end
  end

  context 'with legacy user permissions' do
    let(:access_group) { create(:access_group) }
    let(:user) do
      user = create(:user)
      role.add(user)
      access_group.add(user)
      user
    end
    let(:policy) { described_class.new(user: user, resource: project) }

    context 'with direct project access' do
      before { access_group.add_viewable(project) }
      include_examples 'permission checks', true
    end

    context 'with organization access' do
      before { access_group.add_viewable(organization) }
      include_examples 'permission checks', true
    end

    context 'with data source access' do
      before { access_group.add_viewable(data_source) }
      include_examples 'permission checks', true
    end

    context 'with project group access' do
      let(:project_group) do
        group = create(:project_access_group)
        project.project_groups << group
        project.save!
        group
      end

      before { access_group.add_viewable(project_group) }
      include_examples 'permission checks', true
    end

    context 'with CoC code access' do
      let(:coc_code) { 'authtest1' }

      before do
        project.project_cocs.create!(coc_code: coc_code)
        access_group.update!(coc_codes: [coc_code])
      end

      include_examples 'permission checks', true
    end

    context 'with system group access' do
      before do
        system_group = AccessGroup.system_groups[:data_sources]
        system_group.add(user)
      end

      include_examples 'permission checks', true
    end

    context 'without any access' do
      include_examples 'permission checks', false
    end
  end

  context 'with user access control permissions' do
    let(:user) { create(:acl_user) }
    let(:policy) { described_class.new(user: user, resource: project) }

    context 'with collection access' do
      before do
        user_group = create(:user_group)
        user_group.add(user)
        collection = create(:collection)
        create(:access_control, role: role, collection: collection, user_group: user_group)
        collection.set_viewables({ projects: [project.id] })
      end

      include_examples 'permission checks', true
    end

    context 'with organization access' do
      before do
        user_group = create(:user_group)
        user_group.add(user)
        collection = create(:collection)
        create(:access_control, role: role, collection: collection, user_group: user_group)
        collection.set_viewables({ organizations: [organization.id] })
      end

      include_examples 'permission checks', true
    end

    context 'with data source access' do
      before do
        user_group = create(:user_group)
        user_group.add(user)
        collection = create(:collection)
        create(:access_control, role: role, collection: collection, user_group: user_group)
        collection.set_viewables({ data_sources: [data_source.id] })
      end

      include_examples 'permission checks', true
    end

    context 'with project group access' do
      let(:project_group) do
        group = create(:project_access_group)
        project.project_groups << group
        project.save!
        group
      end

      before do
        user_group = create(:user_group)
        user_group.add(user)
        collection = create(:collection)
        create(:access_control, role: role, collection: collection, user_group: user_group)
        collection.set_viewables({ project_groups: [project_group.id] })
      end

      include_examples 'permission checks', true
    end

    context 'with CoC code access' do
      let(:coc_code) { 'authtest1' }

      before do
        project.project_cocs.create!(coc_code: coc_code)
        user_group = create(:user_group)
        user_group.add(user)
        collection = create(:collection)
        create(:access_control, role: role, collection: collection, user_group: user_group)
        collection.update!(coc_codes: [coc_code])
      end

      include_examples 'permission checks', true
    end

    context 'without any access' do
      include_examples 'permission checks', false
    end

    context 'with system collection access' do
      before do
        user_group = create(:user_group)
        user_group.add(user)
        collection = Collection.system_collection(:data_sources)
        create(:access_control, role: role, collection: collection, user_group: user_group)
      end

      include_examples 'permission checks', true
    end
  end

  describe '#can_see_raw_hmis_data?' do
    let(:user) { create(:acl_user) }
    let(:policy) { described_class.new(user: user, resource: project) }
    let(:data_source_policy) { instance_double(GrdaWarehouse::AuthPolicies::DataSourcePolicy) }

    before do
      allow(user).to receive(:policy_for).with(project.data_source, type: :data_source).
        and_return(data_source_policy)
    end

    it 'delegates to the data source policy' do
      expect(data_source_policy).to receive(:can_see_raw_hmis_data?).and_return(true)
      expect(policy.can_see_raw_hmis_data?).to be true
    end
  end
end
