###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# The HMIS Cross Walk project picker lists can_view_projects projects, but the report may
# only include projects the user can report on (can_view_assigned_reports). A selection
# that resolves to nothing must show no projects, not every active project.
RSpec.describe 'HMIS Cross Walk project scope', type: :request do
  include AccessControlSetup

  let(:user) { create(:acl_user) }
  let(:data_source) { create(:source_data_source) }
  # Non-confidential scoping joins the organization, so the projects need one
  let(:organization) { create(:hud_organization, data_source: data_source) }
  # X: visible to the user (can_view_projects) but not reportable
  let!(:project_x) do
    create(
      :hud_project,
      data_source: data_source,
      OrganizationID: organization.OrganizationID,
      OperatingStartDate: 3.years.ago.to_date,
    )
  end
  # Y: visible and reportable
  let!(:project_y) do
    create(
      :hud_project,
      data_source: data_source,
      OrganizationID: organization.OrganizationID,
      OperatingStartDate: 3.years.ago.to_date,
    )
  end
  # Z: not visible to the user at all
  let!(:project_z) do
    create(
      :hud_project,
      data_source: data_source,
      OrganizationID: organization.OrganizationID,
      OperatingStartDate: 3.years.ago.to_date,
    )
  end

  before do
    grant_hud_report(user, 'warehouse_reports/hmis_cross_walks')

    project_collection = create(:collection)
    project_collection.set_viewables(projects: [project_x.id, project_y.id])
    setup_access_control(user, create(:role, can_view_projects: true), project_collection)

    report_collection = create(:collection)
    report_collection.set_viewables(projects: [project_y.id])
    setup_access_control(user, create(:role, can_view_assigned_reports: true), report_collection)

    sign_in(user)
  end

  def get_index(filters)
    get warehouse_reports_hmis_cross_walks_path, params: { filters: filters }
  end

  it 'includes no projects when every selected project is not reportable' do
    get_index(project_ids: [project_x.id])

    expect(response).to have_http_status(:success)
    expect(assigns(:projects)).to be_empty
  end

  it 'includes only reportable projects when no project is selected' do
    get warehouse_reports_hmis_cross_walks_path

    expect(assigns(:projects)).to contain_exactly(project_y)
  end

  it 'includes the selected project when it is reportable' do
    get_index(project_ids: [project_y.id])

    expect(assigns(:projects)).to contain_exactly(project_y)
  end
end
