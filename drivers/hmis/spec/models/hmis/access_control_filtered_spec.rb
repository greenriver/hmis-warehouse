###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::AccessControl, type: :model do
  describe '.filtered' do
    let!(:data_source) { create :hmis_data_source }
    let!(:other_data_source) { create :hmis_data_source }
    let!(:organization) { create :hmis_hud_organization, data_source: data_source }
    let!(:other_organization) { create :hmis_hud_organization, data_source: data_source }
    let!(:project) { create :hmis_hud_project, data_source: data_source, organization: organization }
    let!(:sibling_project) { create :hmis_hud_project, data_source: data_source, organization: other_organization }
    let!(:project_coc) { create :hmis_hud_project_coc, data_source: data_source, project: project, CoCCode: 'XX-500' }
    let!(:sibling_project_coc) { create :hmis_hud_project_coc, data_source: data_source, project: sibling_project, CoCCode: 'XX-501' }

    let!(:other_role) { create :hmis_role }

    def access_control_for(entity, **attrs)
      create(:hmis_access_control, access_group: create(:hmis_access_group, with_entities: entity), **attrs)
    end

    let!(:data_source_acl) { access_control_for(data_source) }
    let!(:organization_acl) { access_control_for(organization, role: other_role) }
    let!(:project_acl) { access_control_for(project) }
    let!(:other_organization_acl) { access_control_for(other_organization) }
    let!(:sibling_project_acl) { access_control_for(sibling_project, role: other_role) }
    let!(:other_data_source_acl) { access_control_for(other_data_source) }

    it 'returns every access control when all filters are blank' do
      result = Hmis::AccessControl.filtered({ project_id: '', role_id: '' })
      expect(result).to match_array(Hmis::AccessControl.all)
    end

    it 'matches a project through the project, its organization, and its data source' do
      result = Hmis::AccessControl.filtered({ project_id: project.id.to_s })
      expect(result).to contain_exactly(data_source_acl, organization_acl, project_acl)
    end

    it 'matches an organization through the organization and its data source, not its projects' do
      result = Hmis::AccessControl.filtered({ organization_id: organization.id.to_s })
      expect(result).to contain_exactly(data_source_acl, organization_acl)
    end

    it 'matches a data source only through the data source itself' do
      result = Hmis::AccessControl.filtered({ data_source_id: data_source.id.to_s })
      expect(result).to contain_exactly(data_source_acl)
    end

    it 'matches a CoC through projects that have that ProjectCoC' do
      result = Hmis::AccessControl.filtered({ coc_code: 'XX-500' })
      expect(result).to contain_exactly(data_source_acl, organization_acl, project_acl)
    end

    it 'requires every present filter to match' do
      result = Hmis::AccessControl.filtered({ project_id: project.id.to_s, role_id: other_role.id.to_s })
      expect(result).to contain_exactly(organization_acl)
    end

    it 'returns nothing for a project id that does not exist' do
      result = Hmis::AccessControl.filtered({ project_id: '0' })
      expect(result).to be_empty
    end
  end
end
