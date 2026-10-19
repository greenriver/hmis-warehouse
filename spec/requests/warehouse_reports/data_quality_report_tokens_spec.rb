###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'DataQualityReportTokensController', type: :request do
  let!(:collection) { create(:collection) }
  let!(:role) { create(:role, can_view_assigned_reports: true, can_view_all_reports: true, can_view_projects: true) }
  let!(:user) { create(:acl_user) }
  let!(:report_definition) do
    GrdaWarehouse::WarehouseReports::ReportDefinition.create!(
      url: 'warehouse_reports/project/data_quality',
      name: 'Project Data Quality',
      report_group: 'Reports',
      description: 'Project Data Quality',
    )
  end
  let!(:data_source) { create(:grda_warehouse_data_source) }
  let!(:organization) { create(:hud_organization, data_source: data_source) }
  let!(:project) { create(:hud_project, data_source: data_source, OrganizationID: organization.OrganizationID) }
  let!(:other_project) { create(:hud_project, data_source: data_source, OrganizationID: organization.OrganizationID) }
  let!(:project_group) { create(:project_group, projects: [project]) }
  let!(:report) { create(:data_quality_report_version_five, project: project) }
  let!(:other_report) { create(:data_quality_report_version_five, project: other_project) }
  let!(:group_report) { create(:data_quality_report_version_five, project: nil, project_group: project_group) }

  def create_token(report:, token: 'abc123', expires_at: 1.year.from_now)
    GrdaWarehouse::ReportToken.create!(token: token, report_id: report.id, contact_id: 1, expires_at: expires_at)
  end

  before do
    Collection.maintain_system_groups
    collection.set_viewables({ reports: [report_definition.id], projects: [project.id], project_groups: [project_group.id] })
    setup_access_control(user, role, collection)
    sign_in(user)
  end

  describe 'a signed-in user who can view the report' do
    before { create_token(report: report) }

    it 'redirects the project token url to the report page' do
      get "/notifications/abc123/projects/#{project.id}/data_quality_reports/#{report.id}"

      expect(response).to redirect_to(project_data_quality_report_path(project, report))
    end

    it 'redirects the project support url to the report page' do
      get "/notifications/abc123/projects/#{project.id}/data_quality_reports/#{report.id}/support"

      expect(response).to redirect_to(project_data_quality_report_path(project, report))
    end

    it 'redirects the project answers url to the report page' do
      get "/notifications/abc123/projects/#{project.id}/data_quality_reports/#{report.id}/answers"

      expect(response).to redirect_to(project_data_quality_report_path(project, report))
    end

    it 'redirects the project group token urls to the group report page' do
      create_token(report: group_report, token: 'grp456')
      expected = project_group_data_quality_report_path(project_group, group_report)

      ['', '/support', '/answers'].each do |suffix|
        get "/notifications/grp456/project_groups/#{project_group.id}/data_quality_reports/#{group_report.id}#{suffix}"

        expect(response).to redirect_to(expected)
      end
    end

    it 'redirects to the report on the token when the url ids name another report' do
      get "/notifications/abc123/projects/#{other_project.id}/data_quality_reports/#{other_report.id}"

      expect(response).to redirect_to(project_data_quality_report_path(project, report))
    end
  end

  describe 'tokens that do not resolve' do
    it 'returns not found for an unknown token' do
      create_token(report: report)

      get "/notifications/nope/projects/#{project.id}/data_quality_reports/#{report.id}"

      expect(response).to have_http_status(:not_found)
    end

    it 'returns not found for an expired token' do
      create_token(report: report, token: 'old789', expires_at: 1.day.ago)

      get "/notifications/old789/projects/#{project.id}/data_quality_reports/#{report.id}"

      expect(response).to have_http_status(:not_found)
    end

    it 'returns not found when the token report no longer exists' do
      create_token(report: report)
      GrdaWarehouse::ReportToken.where(token: 'abc123').update_all(report_id: 0)

      get "/notifications/abc123/projects/#{project.id}/data_quality_reports/#{report.id}"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'a signed-in user who cannot view the report' do
    before do
      create_token(report: other_report, token: 'other1')
      collection.set_viewables({ reports: [report_definition.id], projects: [project.id] })
      user.clear_memery_cache!
    end

    it 'gets the standard not-authorized redirect instead of the report redirect' do
      get "/notifications/other1/projects/#{other_project.id}/data_quality_reports/#{other_report.id}"

      expect(response).to redirect_to(user.my_root_path)
      expect(flash[:alert]).to eq('Sorry you are not authorized to do that.')
    end
  end

  describe 'a logged-out visitor' do
    before do
      create_token(report: report)
      sign_out(user)
    end

    it 'is sent to sign in, then lands on the report page', :devise_only do
      path = "/notifications/abc123/projects/#{project.id}/data_quality_reports/#{report.id}"

      get path

      expect(response).to redirect_to(new_user_session_path)

      sign_in(user)
      get path

      expect(response).to redirect_to(project_data_quality_report_path(project, report))
    end

    it 'is sent to sign in for an expired token before the lookup', :devise_only do
      create_token(report: report, token: 'old789', expires_at: 1.day.ago)

      get "/notifications/old789/projects/#{project.id}/data_quality_reports/#{report.id}"

      expect(response).to redirect_to(new_user_session_path)
    end

    it 'is refused', :jwt_only do
      expect do
        get "/notifications/abc123/projects/#{project.id}/data_quality_reports/#{report.id}"
      end.to raise_error(Idp::UnauthenticatedRequestError)
    end
  end
end
