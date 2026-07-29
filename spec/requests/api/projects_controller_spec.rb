###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# First back-end coverage for the project-picker endpoint shared by HUD report
# filter forms. viewable_by's permission arg is a hard gate for ACL users but
# ignored for legacy role-based users; these specs pin both behaviors plus the
# param filters the PATH report form relies on (funder_codes, project_types).
RSpec.describe Api::ProjectsController, type: :request do
  include AccessControlSetup

  before(:all) { GrdaWarehouse::Utility.clear! }
  after(:all) { GrdaWarehouse::Utility.clear! }

  let!(:data_source) { create(:source_data_source) }
  let!(:organization) { create(:hud_organization, data_source_id: data_source.id) }

  # PATH-eligible: Street Outreach (4) with PATH funder (21)
  let!(:so_path_project) do
    create(
      :hud_project,
      data_source_id: data_source.id,
      OrganizationID: organization.OrganizationID,
      ProjectType: 4,
    )
  end
  let!(:so_path_funder) do
    create(
      :hud_funder,
      data_source_id: data_source.id,
      ProjectID: so_path_project.ProjectID,
      Funder: 21,
    )
  end
  # Control: PATH type, but no PATH funder
  let!(:so_project_without_path_funder) do
    create(
      :hud_project,
      data_source_id: data_source.id,
      OrganizationID: organization.OrganizationID,
      ProjectType: 4,
    )
  end
  # Control: PATH funder, but not a PATH type (ES = 1)
  let!(:es_path_funded_project) do
    create(
      :hud_project,
      data_source_id: data_source.id,
      OrganizationID: organization.OrganizationID,
      ProjectType: 1,
    )
  end
  let!(:es_funder) do
    create(
      :hud_funder,
      data_source_id: data_source.id,
      ProjectID: es_path_funded_project.ProjectID,
      Funder: 21,
    )
  end

  let(:granted_project_ids) { [so_path_project.id, so_project_without_path_funder.id, es_path_funded_project.id] }

  def returned_project_ids
    JSON.parse(response.body)['results'].flat_map { |group| group['children'] }.map { |child| child['id'] }
  end

  def post_projects(params = {})
    post api_projects_path(format: :json), params: params
  end

  context 'with a legacy role-based user' do
    let(:user) { create(:user) }
    let(:role) { create(:role, can_view_assigned_reports: true) }

    before do
      user.legacy_roles << role
      user.add_viewable(data_source)
      sign_in(user)
    end

    it 'returns projects viewable through entity assignments when no permission is given' do
      post_projects
      expect(returned_project_ids).to match_array(granted_project_ids)
    end

    it 'returns the same projects when a permission is given (legacy branch ignores it)' do
      post_projects(permission: 'can_view_assigned_reports')
      expect(returned_project_ids).to match_array(granted_project_ids)
    end
  end

  context 'with an ACL user whose role has can_view_assigned_reports but not can_view_projects' do
    let(:user) { create(:acl_user) }
    let(:role) { create(:role, can_view_assigned_reports: true) }
    let(:collection) { create(:collection) }
    # Excluded row: in no collection; proves results are attributable to the
    # grant rather than fixture leakage.
    let!(:ungranted_project) do
      create(
        :hud_project,
        data_source_id: data_source.id,
        OrganizationID: organization.OrganizationID,
        ProjectType: 4,
      )
    end

    before do
      collection.set_viewables(projects: granted_project_ids)
      setup_access_control(user, role, collection)
      sign_in(user)
    end

    it 'returns no projects when no permission is given (endpoint defaults to can_view_projects)' do
      post_projects
      expect(returned_project_ids).to eq([])
    end

    it 'returns granted projects when permission=can_view_assigned_reports' do
      post_projects(permission: 'can_view_assigned_reports')
      expect(returned_project_ids).to match_array(granted_project_ids)
      expect(returned_project_ids).not_to include(ungranted_project.id)
    end

    it 'ignores a permission that is not in the Role.permissions allow-list' do
      post_projects(permission: 'destroy_all')
      expect(returned_project_ids).to eq([])
    end

    context 'filter params as sent by the PATH report form' do
      it 'limits by funder_codes' do
        post_projects(permission: 'can_view_assigned_reports', funder_codes: ['21'])
        expect(returned_project_ids).to contain_exactly(so_path_project.id, es_path_funded_project.id)
      end

      it 'limits by project_types' do
        post_projects(permission: 'can_view_assigned_reports', project_types: ['so'])
        expect(returned_project_ids).to contain_exactly(so_path_project.id, so_project_without_path_funder.id)
      end

      it 'limits by project_types and funder_codes together' do
        post_projects(permission: 'can_view_assigned_reports', project_types: ['so', 'services_only'], funder_codes: ['21'])
        expect(returned_project_ids).to contain_exactly(so_path_project.id)
      end

      it 'treats a blanks-only project_types array as no type restriction' do
        # Rack parses a serialized empty array (`project_types[]=`) as [""].
        post_projects(permission: 'can_view_assigned_reports', project_types: [''])
        expect(returned_project_ids).to match_array(granted_project_ids)
      end
    end
  end

  context 'with an ACL user whose role has can_view_projects' do
    let(:user) { create(:acl_user) }
    let(:role) { create(:role, can_view_projects: true) }
    let(:collection) { create(:collection) }
    let!(:ungranted_project) do
      create(
        :hud_project,
        data_source_id: data_source.id,
        OrganizationID: organization.OrganizationID,
        ProjectType: 4,
      )
    end

    before do
      collection.set_viewables(projects: granted_project_ids)
      setup_access_control(user, role, collection)
      sign_in(user)
    end

    it 'returns granted projects with the default permission' do
      post_projects
      expect(returned_project_ids).to match_array(granted_project_ids)
      expect(returned_project_ids).not_to include(ungranted_project.id)
    end
  end
end
