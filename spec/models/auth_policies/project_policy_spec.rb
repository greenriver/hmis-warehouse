require 'rails_helper'

RSpec.describe GrdaWarehouse::AuthPolicies::ProjectPolicy, type: :model do
  let(:data_source) { create :data_source_fixed_id }
  let(:organization) { create :hud_organization, data_source: data_source }
  let(:project) { create :grda_warehouse_hud_project, organization: organization, data_source: data_source }
  let(:coc_code) { 'XX-500' }

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
      can_upload_hud_zips: false,
      can_edit_data_sources: false,
    }
  end

  let(:role) { create(:role, **permissions.compact_blank) }

  let(:hud_data_access_role) { create(:role, can_upload_hud_zips: true, can_edit_data_sources: true) }

  shared_examples 'permission checks with access' do
    it 'grants configured permissions' do
      # Check permissions that should be granted by our role
      expect(policy.can_view?).to be true
      expect(policy.can_view_clients?).to be true
    end

    it 'denies unconfigured permissions' do
      # Check permissions that weren't granted to our role
      expect(policy.can_edit?).to be false
      expect(policy.can_delete?).to be false
      expect(policy.can_view_imports?).to be false
      expect(policy.can_view_project_locations?).to be false
    end
  end

  shared_examples 'permission checks without access' do
    it 'denies all permissions when user lacks access' do
      expect(policy.can_view?).to be false
      expect(policy.can_view_clients?).to be false
      expect(policy.can_edit?).to be false
      expect(policy.can_delete?).to be false
      expect(policy.can_view_imports?).to be false
      expect(policy.can_view_project_locations?).to be false
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
    let(:policy) { user.policy_for(project) }

    context 'with full data source permissions' do
      before do
        access_group.add_viewable(data_source)
        hud_data_access_role.add(user)
      end
      it 'allows access to raw HMIS data' do
        expect(policy.can_see_raw_hmis_data?).to be true
      end
    end

    context 'with direct project access' do
      before { access_group.add_viewable(project) }
      include_examples 'permission checks with access'
    end

    context 'with organization access' do
      before { access_group.add_viewable(organization) }
      include_examples 'permission checks with access'
    end

    context 'with data source access' do
      before { access_group.add_viewable(data_source) }
      include_examples 'permission checks with access'
    end

    context 'with project group access' do
      let(:project_group) do
        group = create(:project_access_group)
        project.project_groups << group
        project.save!
        group
      end

      before { access_group.add_viewable(project_group) }
      include_examples 'permission checks with access'
    end

    context 'with CoC code access' do
      before do
        project.project_cocs.create!(coc_code: coc_code)
        access_group.update!(coc_codes: [coc_code])
      end

      include_examples 'permission checks with access'
    end

    context 'with system group access' do
      before do
        system_group = AccessGroup.system_groups[:data_sources]
        system_group.add(user)
      end

      include_examples 'permission checks with access'
    end

    context 'without any access' do
      include_examples 'permission checks without access'
    end
  end

  context 'with user access control permissions' do
    let(:user) { create(:acl_user) }
    let(:policy) { user.policy_for(project) }
    let(:collection) { create(:collection) }
    let(:user_group) { create(:user_group) }

    before do
      user_group.add(user)
      create(:access_control, role: role, collection: collection, user_group: user_group)
    end

    context 'with full data source permissions' do
      let(:role) { hud_data_access_role }

      before do
        collection.set_viewables({ data_sources: [data_source.id] })
      end

      it 'allows access to raw HMIS data' do
        expect(policy.can_see_raw_hmis_data?).to be true
      end
    end

    context 'with collection access' do
      before do
        collection.set_viewables({ projects: [project.id] })
      end

      include_examples 'permission checks with access'
    end

    context 'with organization access' do
      before do
        collection.set_viewables({ organizations: [organization.id] })
      end

      include_examples 'permission checks with access'
    end

    context 'with data source access' do
      before do
        collection.set_viewables({ data_sources: [data_source.id] })
      end

      include_examples 'permission checks with access'
    end

    context 'with project group access' do
      let(:project_group) do
        group = create(:project_access_group)
        project.project_groups << group
        project.save!
        group
      end

      before do
        collection.set_viewables({ project_groups: [project_group.id] })
      end

      include_examples 'permission checks with access'
    end

    context 'with CoC code access' do
      before do
        project.project_cocs.create!(coc_code: coc_code)
        collection.update!(coc_codes: [coc_code])
      end

      include_examples 'permission checks with access'
    end

    context 'without any access' do
      include_examples 'permission checks without access'
    end

    context 'with system collection access' do
      let(:collection) { Collection.system_collection(:data_sources) }
      include_examples 'permission checks with access'
    end
  end
end
