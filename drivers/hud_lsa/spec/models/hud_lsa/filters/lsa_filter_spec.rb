###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# With no projects picked the LSA runs system-wide. Picking only projects the user
# can't report on must leave it with no projects, not widen it to system-wide.
RSpec.describe HudLsa::Filters::LsaFilter, type: :model do
  include AccessControlSetup

  let(:coc_code) { 'XX-500' }
  let(:user) { create(:acl_user) }
  let(:data_source) { create(:source_data_source) }
  # Non-confidential scoping joins the organization, so the projects need one
  let(:organization) { create(:hud_organization, data_source: data_source) }
  let(:psh_type) { HudHelper.util.project_type_number_from_code(:psh).first }
  let!(:visible_project) { create_coc_funded_project }
  let!(:other_visible_project) { create_coc_funded_project }
  let!(:hidden_project) { create_coc_funded_project }
  let(:role) { create(:role, can_view_assigned_reports: true) }

  before do
    collection = create(:collection)
    collection.set_viewables(projects: [visible_project.id, other_visible_project.id])
    setup_access_control(user, role, collection)
  end

  def create_coc_funded_project
    project = create(
      :hud_project,
      data_source: data_source,
      OrganizationID: organization.OrganizationID,
      ProjectType: psh_type,
      ContinuumProject: 1,
    )
    create(
      :hud_project_coc,
      data_source: data_source,
      project_id: project.project_id,
      CoCCode: coc_code,
    )
    project
  end

  # Built through update, like the controller, so project types are only what was submitted
  # rather than the defaults, which would add every project of those types
  def filter_for(project_ids, project_group_ids: [], organization_ids: [])
    filter = described_class.new(user_id: user.id)
    filter.update(
      coc_code: coc_code,
      project_ids: project_ids,
      project_group_ids: project_group_ids,
      organization_ids: organization_ids,
    )
  end

  it 'returns no projects when every picked project is hidden' do
    expect(filter_for([hidden_project.id]).effective_project_ids).to eq([])
  end

  it 'returns only the picked project when it is visible' do
    expect(filter_for([visible_project.id]).effective_project_ids).to eq([visible_project.id])
  end

  it 'returns every visible CoC-funded project when nothing is picked' do
    expect(filter_for([]).effective_project_ids).to contain_exactly(visible_project.id, other_visible_project.id)
  end

  describe 'with a project group' do
    # Seeing a group only narrows the report to the user's projects in it
    def filter_for_group(projects)
      project_group = create(:project_group, projects: projects)
      grant_project_group_access(user, role, [project_group], mode: :acl)
      filter_for([], project_group_ids: [project_group.id])
    end

    it 'returns no projects when none of the group projects are visible' do
      expect(filter_for_group([hidden_project]).effective_project_ids).to eq([])
    end

    it 'returns only the visible group projects' do
      expect(filter_for_group([visible_project, hidden_project]).effective_project_ids).to eq([visible_project.id])
    end
  end

  describe 'with an organization' do
    # The LSA form doesn't offer an organization picker, but the param is still accepted
    it 'returns no projects when none of the organization projects are visible' do
      hidden_organization = create(:hud_organization, data_source: data_source)
      hidden_project.update!(OrganizationID: hidden_organization.OrganizationID)

      expect(filter_for([], organization_ids: [hidden_organization.id]).effective_project_ids).to eq([])
    end
  end
end
