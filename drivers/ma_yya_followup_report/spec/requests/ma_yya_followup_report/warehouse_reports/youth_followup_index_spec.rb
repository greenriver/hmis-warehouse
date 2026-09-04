###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'MaYyaFollowupReport::WarehouseReports::YouthFollowup#index', type: :request do
  let!(:collection) { create(:collection) }
  let!(:role) { create(:role, can_view_assigned_reports: true, can_view_clients: true, can_view_client_name: true, can_view_project_related_filters: true) }
  let!(:user) { create(:acl_user) }

  let!(:hmis_ds) { create(:hmis_primary_data_source) }
  let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
  let!(:organization) { create(:hud_organization, data_source: hmis_ds) }
  let!(:project) { create(:hud_project, organization: organization, data_source: hmis_ds, ProjectType: 1) }
  let!(:other_project) { create(:hud_project, organization: organization, data_source: hmis_ds, ProjectType: 1) }

  let(:on_date) { Date.current }
  # Report#initialize derives the enrollment window from `on`; FilterForAge computes age at the window start.
  let(:window_start) { on_date - 3.months + 1.week }
  let(:youth_dob) { window_start - 20.years }
  let(:adult_dob) { window_start - 30.years }

  let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Restricted', last_name: 'Client') }
  let!(:restricted_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Restricted', LastName: 'Client', DOB: youth_dob) }
  let!(:open_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Open', LastName: 'Doe', DOB: youth_dob) }
  let!(:other_project_client) { create(:grda_warehouse_hud_client, FirstName: 'Elsewhere', LastName: 'Person', DOB: youth_dob) }
  let!(:adult_client) { create(:grda_warehouse_hud_client, FirstName: 'Older', LastName: 'Adult', DOB: adult_dob) }

  def build_entry(client, in_project)
    create(:she_entry, client: client, data_source: hmis_ds, project: in_project, project_type: 1, first_date_in_program: on_date - 1.month)
  end
  let!(:restricted_she) { build_entry(restricted_destination_client, project) }
  let!(:open_she) { build_entry(open_destination_client, project) }
  let!(:other_project_she) { build_entry(other_project_client, other_project) }
  let!(:adult_she) { build_entry(adult_client, project) }

  let(:filter_params) do
    { filter: { on: on_date.to_s, project_ids: [project.id], age_ranges: ['eighteen_to_twenty_four'] } }
  end

  before do
    Rails.cache.clear
    Collection.maintain_system_groups
    collection.set_viewables({ projects: [project.id] })
    setup_access_control(user, role, collection)
    allow_any_instance_of(MaYyaFollowupReport::WarehouseReports::YouthFollowupController).to receive(:report_visible?).and_return(true)
    GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_destination_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s)
    restricted_source_client.mark_as_restricted!(user: hmis_user)
    sign_in(user)
  end

  it 'lists clients enrolled in the selected project, redacting the restricted client' do
    get ma_yya_followup_report_warehouse_reports_youth_followup_index_path, params: filter_params

    expect(response).to have_http_status(:success)
    expect(response.body).to include('Open Doe')
    expect(response.body).to include(GrdaWarehouse::PiiProvider::NAME_REDACTED)
    expect(response.body).not_to include('Restricted')
    expect(response.body).not_to include('Elsewhere Person')
  end

  it 'excludes clients outside the selected age range' do
    get ma_yya_followup_report_warehouse_reports_youth_followup_index_path, params: filter_params

    expect(response).to have_http_status(:success)
    expect(response.body).to include('Open Doe')
    expect(response.body).not_to include('Older Adult')
  end

  it 'renders no clients when the filter selects no project and no age range' do
    get ma_yya_followup_report_warehouse_reports_youth_followup_index_path

    expect(response).to have_http_status(:success)
    expect(response.body).not_to include('Open Doe')
    expect(response.body).not_to include(GrdaWarehouse::PiiProvider::NAME_REDACTED)
  end
end
