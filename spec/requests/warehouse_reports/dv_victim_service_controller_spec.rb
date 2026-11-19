###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'WarehouseReports::DvVictimServiceController', type: :request do
  let!(:user) { create(:acl_user) }
  let!(:collection) { create(:collection) }
  let!(:role) do
    create(
      :role,
      can_view_all_reports: true,
      can_view_assigned_reports: true,
      can_view_projects: true,
      can_view_client_name: true,
      can_view_clients: true,
    )
  end
  let!(:report) { create(:touch_point_report, url: 'warehouse_reports/dv_victim_service', name: 'DV Victim Service') }

  let!(:data_source) { create(:grda_warehouse_data_source) }
  let!(:organization) { create(:hud_organization, data_source: data_source) }
  let!(:visible_project) { create(:hud_project, data_source: data_source, OrganizationID: organization.OrganizationID, ProjectType: 3) }
  let!(:hidden_project) { create(:hud_project, data_source: data_source, OrganizationID: organization.OrganizationID, ProjectType: 3) }

  let!(:destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Dvtest', LastName: 'Client') }
  let!(:source_client) { create(:grda_warehouse_hud_client, data_source: data_source, FirstName: 'Dvtest', LastName: 'Client') }

  def build_enrollment(project)
    create(
      :hud_enrollment,
      data_source: data_source,
      PersonalID: source_client.PersonalID,
      ProjectID: project.ProjectID,
      EntryDate: 1.month.ago.to_date,
    )
  end

  def build_fleeing_record(enrollment)
    create(
      :hud_health_and_dv,
      data_source: data_source,
      PersonalID: source_client.PersonalID,
      EnrollmentID: enrollment.EnrollmentID,
      InformationDate: 1.week.ago.to_date,
      CurrentlyFleeing: 1,
    )
  end

  let!(:visible_enrollment) { build_enrollment(visible_project) }
  let!(:hidden_enrollment) { build_enrollment(hidden_project) }
  let!(:hidden_fleeing_record) { build_fleeing_record(hidden_enrollment) }

  before do
    Collection.maintain_system_groups
    collection.set_viewables({ reports: [report.id], projects: [visible_project.id] })
    setup_access_control(user, role, collection)
    GrdaWarehouse::WarehouseClient.create!(
      destination_id: destination_client.id,
      source_id: source_client.id,
      data_source_id: data_source.id,
      id_in_source: source_client.PersonalID,
    )
    sign_in user
  end

  def client_link
    appropriate_client_path(destination_client.id)
  end

  it 'does not list a client whose fleeing record is on an enrollment at a project the user cannot see' do
    get warehouse_reports_dv_victim_service_index_path

    expect(response).to have_http_status(:success)
    expect(response.body).to include('No clients found.')
    expect(response.body).not_to include(client_link)
  end

  it 'lists the client when the fleeing record is on the visible enrollment' do
    build_fleeing_record(visible_enrollment)

    get warehouse_reports_dv_victim_service_index_path

    expect(response).to have_http_status(:success)
    expect(response.body).to include(client_link)
  end
end
