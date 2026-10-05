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

  # Projects the user reaches in different ways, each with one youth enrolled, plus one youth
  # enrolled in both `project` and `nameless_project`.
  shared_context 'projects with mixed access' do
    let(:filter_permission) { true }
    let!(:nameless_role) { create(:role, can_view_assigned_reports: true, can_view_clients: true, can_view_client_name: false, can_view_project_related_filters: filter_permission) }
    let!(:nameless_collection) { create(:collection) }
    # Viewable, but through a role without `can_view_client_name`.
    let!(:nameless_project) { create(:hud_project, organization: organization, data_source: hmis_ds, ProjectType: 1) }
    # In the user's collection, but the user can't report on confidential projects.
    let!(:confidential_project) { create(:hud_project, organization: organization, data_source: hmis_ds, ProjectType: 1, confidential: true) }

    let!(:multi_project_client) { create(:grda_warehouse_hud_client, FirstName: 'Multi', LastName: 'Project', DOB: youth_dob) }
    let!(:nameless_client) { create(:grda_warehouse_hud_client, FirstName: 'Nameless', LastName: 'Person', DOB: youth_dob) }
    let!(:confidential_client) { create(:grda_warehouse_hud_client, FirstName: 'Confidential', LastName: 'Person', DOB: youth_dob) }

    let!(:multi_she) { build_entry(multi_project_client, project) }
    let!(:multi_nameless_she) { build_entry(multi_project_client, nameless_project) }
    let!(:nameless_she) { build_entry(nameless_client, nameless_project) }
    let!(:confidential_she) { build_entry(confidential_client, confidential_project) }

    let(:selected_project_ids) { [project.id] }
    let(:filter_params) do
      { filter: { on: on_date.to_s, project_ids: selected_project_ids, age_ranges: ['eighteen_to_twenty_four'] } }
    end

    before do
      collection.set_viewables({ projects: [project.id, confidential_project.id] })
      nameless_collection.set_viewables({ projects: [nameless_project.id] })
      setup_access_control(user, nameless_role, nameless_collection)
    end

    # Full href so one client id can't match as a prefix of another
    def client_link(id)
      %(href="#{client_path(id)}")
    end

    def run_report(params = filter_params)
      get ma_yya_followup_report_warehouse_reports_youth_followup_index_path, params: params
      expect(response).to have_http_status(:success)
    end
  end

  describe 'project selection' do
    include_context 'projects with mixed access'

    context 'when only an age range is selected' do
      it 'includes youth from every project the user can view' do
        run_report({ filter: { on: on_date.to_s, age_ranges: ['eighteen_to_twenty_four'] } })

        expect(response.body).to include('Open Doe', 'Multi Project', client_link(nameless_client.id))
        expect(response.body).not_to include(client_link(other_project_client.id))
        expect(response.body).not_to include(client_link(confidential_client.id))
        expect(response.body).not_to include('Older Adult')
      end
    end

    context 'when a project outside the user\'s access is selected' do
      let(:selected_project_ids) { [project.id, other_project.id] }

      it 'excludes clients enrolled only in that project' do
        run_report

        expect(response.body).to include('Open Doe')
        expect(response.body).not_to include(client_link(other_project_client.id))
      end
    end

    context 'when a confidential project is selected' do
      let(:selected_project_ids) { [project.id, confidential_project.id] }

      it 'excludes clients enrolled only in that project' do
        run_report

        expect(response.body).to include('Open Doe')
        expect(response.body).not_to include(client_link(confidential_client.id))
      end
    end

    context 'when the user cannot see project-related filters' do
      let(:filter_permission) { false }
      let!(:role) { create(:role, can_view_assigned_reports: true, can_view_clients: true, can_view_client_name: true, can_view_project_related_filters: false) }

      it 'still limits the report to the selected projects' do
        run_report

        expect(response.body).to include('Open Doe')
        expect(response.body).not_to include(client_link(nameless_client.id))
        expect(response.body).not_to include(client_link(other_project_client.id))
      end
    end
  end

  describe 'empty results' do
    include_context 'projects with mixed access'

    context 'when only unauthorized projects are selected' do
      let(:selected_project_ids) { [other_project.id, confidential_project.id] }

      it 'renders no clients' do
        run_report

        expect(response.body).to include('No Clients found.')
      end
    end
  end

  describe 'name visibility across projects' do
    include_context 'projects with mixed access'

    context 'with both the name-granting and the nameless project selected' do
      let(:selected_project_ids) { [project.id, nameless_project.id] }

      it 'redacts a client whose only in-range project does not allow names' do
        run_report

        expect(response.body).to include(client_link(nameless_client.id))
        expect(response.body).not_to include('Nameless')
      end

      it 'shows a client\'s name when any of their in-range projects allows it' do
        run_report

        expect(response.body).to include('Multi Project')
      end
    end

    context 'with only the nameless project selected' do
      let(:selected_project_ids) { [nameless_project.id] }

      it 'redacts a client whose name is only allowed through an unselected project' do
        run_report

        expect(response.body).to include(client_link(multi_project_client.id))
        expect(response.body).not_to include('Multi Project')
      end
    end
  end
end
