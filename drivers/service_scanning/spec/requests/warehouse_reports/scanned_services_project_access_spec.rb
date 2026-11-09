###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'ServiceScanning::WarehouseReports::ScannedServicesController project access', type: :request do
  let!(:user) { create(:acl_user) }
  # Report access without can_view_projects, matching the permission the project picker uses
  let!(:role) do
    create(
      :role,
      can_use_service_register: true,
      can_view_assigned_reports: true,
      can_view_projects: false,
    )
  end
  let!(:collection) { create(:collection) }
  let!(:report) { create(:touch_point_report, url: 'service_scanning/warehouse_reports/scanned_services', name: 'Scanned Services') }

  # viewable_by applies non_confidential, which inner-joins the organization
  let!(:organization) { create(:hud_organization) }
  let!(:assigned_project) { create(:hud_project, ProjectName: 'Assigned Scan Project', organization: organization, data_source: organization.data_source) }
  let!(:other_project) { create(:hud_project, ProjectName: 'Other Scan Project', organization: organization, data_source: organization.data_source) }
  let!(:client) { create(:grda_warehouse_hud_client) }

  before do
    [assigned_project, other_project].each do |project|
      ServiceScanning::OtherService.create!(client_id: client.id, project: project, provided_at: Time.current, user: user)
    end
    Rails.cache.clear
    Collection.maintain_system_groups
    collection.set_viewables({ reports: [report.id], projects: [assigned_project.id] })
    setup_access_control(user, role, collection)
    sign_in user
  end

  after { GrdaWarehouse::Config.invalidate_cache }

  def get_report(project_ids)
    filters = {
      start: Date.current.to_s,
      end: (Date.current + 1.day).to_s,
      project_ids: project_ids,
      service_type: 'other',
    }
    get service_scanning_warehouse_reports_scanned_services_path(filters: filters)
  end

  it 'reports on a picked project the user can report on without can_view_projects' do
    get_report([assigned_project.id])

    expect(response).to have_http_status(:success)
    expect(response.body).to include('Assigned Scan Project')
  end

  it 'drops a picked project the user cannot report on' do
    get_report([assigned_project.id, other_project.id])

    expect(response).to have_http_status(:success)
    expect(response.body).to include('Assigned Scan Project')
    expect(response.body).not_to include('Other Scan Project')
  end
end
