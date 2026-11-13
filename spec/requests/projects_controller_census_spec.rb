###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# The project page census is built from a report filter, which drops projects
# the user can't report on. A user who can view the project but not report on
# it should not get an empty chart.
RSpec.describe 'ProjectsController#show census', type: :request do
  include HudReportAccess

  let!(:data_source) { create(:source_data_source) }
  let!(:organization) { create(:hud_organization, data_source_id: data_source.id) }
  let!(:project) do
    create(:hud_project, data_source_id: data_source.id, OrganizationID: organization.OrganizationID, ProjectType: 1)
  end

  let(:user) { create(:acl_user) }
  let(:view_role) { create(:role, can_view_projects: true) }

  before do
    Collection.maintain_system_groups
    grant_project_access(user, view_role, [project], mode: :acl)
    grant_hud_report(user, 'censuses')
    sign_in(user)
  end

  it 'hides the census when the user can view but not report on the project' do
    get project_path(project)

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include('Nightly Census')
  end

  it 'shows the census when the user can also report on the project' do
    report_role = create(:role, can_view_assigned_reports: true)
    grant_project_access(user, report_role, [project], mode: :acl)

    get project_path(project)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Nightly Census')
  end
end
