###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AccessControl, type: :model do
  describe '.filtered' do
    let!(:data_source) { create :data_source_fixed_id }
    let!(:other_data_source) { create :grda_warehouse_data_source, source_type: :sftp }
    let!(:organization) { create :grda_warehouse_hud_organization, OrganizationName: 'Org A' }
    let!(:other_organization) { create :grda_warehouse_hud_organization, OrganizationName: 'Org B' }
    let!(:project) { create :grda_warehouse_hud_project, organization: organization }
    let!(:sibling_project) { create :grda_warehouse_hud_project, organization: other_organization }
    let!(:project_coc) { create :hud_project_coc, ProjectID: project.ProjectID, data_source_id: data_source.id, CoCCode: 'XX-500' }
    let!(:sibling_project_coc) { create :hud_project_coc, ProjectID: sibling_project.ProjectID, data_source_id: data_source.id, CoCCode: 'XX-501' }
    let!(:coc_lookup) { create :lookup_coc, coc_code: 'XX-500' }
    let!(:unused_coc_lookup) { create :lookup_coc, coc_code: 'XX-502', official_name: 'Fake CoC 502' }

    let!(:role) { create :role }
    let!(:other_role) { create :role }
    let!(:user_group) { create :user_group }
    let!(:other_user_group) { create :user_group }

    def access_control_for(viewables, role: self.role, user_group: self.user_group)
      collection = create(:collection)
      collection.set_viewables(viewables)
      create(:access_control, collection: collection, role: role, user_group: user_group)
    end

    let!(:data_source_acl) { access_control_for({ data_sources: [data_source.id] }) }
    let!(:organization_acl) { access_control_for({ organizations: [organization.id] }, role: other_role) }
    let!(:project_acl) { access_control_for({ projects: [project.id] }, user_group: other_user_group) }
    let!(:coc_lookup_acl) { access_control_for({ coc_codes: [coc_lookup.id] }) }
    let!(:unused_coc_lookup_acl) { access_control_for({ coc_codes: [unused_coc_lookup.id] }) }
    let!(:other_organization_acl) { access_control_for({ organizations: [other_organization.id] }) }
    let!(:sibling_project_acl) { access_control_for({ projects: [sibling_project.id] }, role: other_role) }
    let!(:other_data_source_acl) { access_control_for({ data_sources: [other_data_source.id] }, user_group: other_user_group) }

    it 'returns every access control when all filters are blank' do
      result = AccessControl.user_managed.filtered(ActionController::Parameters.new(project_id: '', role_id: ''))
      expect(result).to match_array(AccessControl.user_managed)
    end

    it 'matches a project through the project, its organization, its data source, and its CoC code' do
      result = AccessControl.user_managed.filtered({ project_id: project.id.to_s })
      expect(result).to contain_exactly(data_source_acl, organization_acl, project_acl, coc_lookup_acl)
    end

    it 'matches an organization through the organization and its data source, not its projects' do
      result = AccessControl.user_managed.filtered({ organization_id: organization.id.to_s })
      expect(result).to contain_exactly(data_source_acl, organization_acl)
    end

    it 'matches a data source only through the data source itself' do
      result = AccessControl.user_managed.filtered({ data_source_id: data_source.id.to_s })
      expect(result).to contain_exactly(data_source_acl)
    end

    it 'matches a CoC through projects with that ProjectCoC and through the CoC code entity' do
      result = AccessControl.user_managed.filtered({ coc_code: 'XX-500' })
      expect(result).to contain_exactly(data_source_acl, organization_acl, project_acl, coc_lookup_acl)
    end

    it 'matches a CoC that no project uses when a collection lists the CoC code' do
      result = AccessControl.user_managed.filtered({ coc_code: 'XX-502' })
      expect(result).to contain_exactly(unused_coc_lookup_acl)
    end

    it 'requires every present filter to match' do
      result = AccessControl.user_managed.filtered({ project_id: project.id.to_s, role_id: other_role.id.to_s })
      expect(result).to contain_exactly(organization_acl)
    end

    it 'returns nothing when the user group and role filters never appear together' do
      result = AccessControl.user_managed.filtered({ user_group_id: other_user_group.id.to_s, role_id: other_role.id.to_s })
      expect(result).to be_empty
    end

    it 'narrows by the user through their user group memberships' do
      member = create(:acl_user)
      other_user_group.add(member)
      result = AccessControl.user_managed.filtered({ user_id: member.id.to_s, project_id: project.id.to_s })
      expect(result).to contain_exactly(project_acl)
    end

    it 'matches an organization whose data source was deleted through the organization alone' do
      deleted_data_source = create(:grda_warehouse_data_source, source_type: :sftp)
      orphan_organization = create(:grda_warehouse_hud_organization, data_source_id: deleted_data_source.id)
      deleted_data_source.update_column(:deleted_at, Time.current)
      orphan_organization_acl = access_control_for({ organizations: [orphan_organization.id] })
      result = AccessControl.user_managed.filtered({ organization_id: orphan_organization.id.to_s })
      expect(result).to contain_exactly(orphan_organization_acl)
    end

    it 'returns nothing for a project id that does not exist' do
      result = AccessControl.user_managed.filtered({ project_id: '0' })
      expect(result).to be_empty
    end
  end
end
