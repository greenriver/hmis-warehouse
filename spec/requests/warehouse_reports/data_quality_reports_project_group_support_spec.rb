###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'DataQualityReportsProjectGroupController#support', type: :request do
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
  let!(:project_a) { create(:hud_project, data_source: data_source, OrganizationID: organization.OrganizationID) }
  let!(:project_b) { create(:hud_project, data_source: data_source, OrganizationID: organization.OrganizationID) }
  let!(:project_group) { GrdaWarehouse::ProjectGroup.create!(name: 'DQ group', projects: [project_a, project_b]) }

  let!(:collection_a) { create(:collection) }
  let!(:collection_b) { create(:collection) }
  let!(:role_a) do
    create(
      :role,
      can_view_all_reports: true,
      can_view_assigned_reports: true,
      can_view_projects: true,
      can_view_clients: true,
      can_view_client_name: true,
      can_view_full_ssn: true,
      can_view_full_dob: true,
    )
  end
  let!(:role_b) { create(:role, can_view_projects: true, can_view_assigned_reports: true) }

  let!(:client_a) { create(:grda_warehouse_hud_client, FirstName: 'Alpha', LastName: 'Allowed') }
  let!(:client_b) { create(:grda_warehouse_hud_client, FirstName: 'Bravo', LastName: 'Blocked') }

  before do
    Collection.maintain_system_groups
    collection_a.set_viewables({ reports: [report_definition.id], projects: [project_a.id] })
    # A project group in a collection grants that collection's role on every project in the
    # group, so the group sits with the role that has no PII permissions.
    collection_b.set_viewables({ projects: [project_b.id], project_groups: [project_group.id] })
    setup_access_control(user, role_a, collection_a)
    setup_access_control(user, role_b, collection_b)
    sign_in(user)
  end

  # Cells for each table row, keyed by the client id in the first cell.
  def table_rows
    Nokogiri::HTML(response.body).css('table.table-hover tbody tr').to_h do |tr|
      cells = tr.css('td').map { |td| td.text.strip }
      [cells.first.to_i, cells]
    end
  end

  def add_dq_row(report:, client:, project:, ssn:)
    Reporting::DataQualityReports::Enrollment.create!(
      report_id: report.id,
      client_id: client.id,
      project_id: project.id,
      project_name: project.ProjectName,
      enrolled: true,
      dob_after_entry_date: true,
      entry_date: Date.new(2016, 1, 1),
      calculated_at: Time.current,
      first_name: client.FirstName,
      last_name: client.LastName,
      dob: Date.new(1985, 6, 15),
      ssn: ssn,
    )
  end

  # Can open the group report, and has can_view_clients only on a project outside the group.
  def sign_in_viewer_without_can_view_clients_in_group
    viewer = create(:acl_user)
    setup_access_control(viewer, role_b, collection_b)
    outside_collection = create(:collection)
    outside_collection.set_viewables({ reports: [report_definition.id], projects: [create(:hud_project).id] })
    setup_access_control(viewer, create(:role, can_view_clients: true, can_view_all_reports: true, can_view_assigned_reports: true), outside_collection)
    sign_in(viewer)
    viewer
  end

  shared_examples 'a per-project PII policy' do
    before do
      add_dq_row(report: report, client: client_a, project: project_a, ssn: '111223333')
      add_dq_row(report: report, client: client_b, project: project_b, ssn: '444556666')
    end

    it 'shows PII for the row in the project the role allows and redacts the row in the other project' do
      get support_project_group_data_quality_report_path(project_group, report, individual: true, method: 'dob_after_entry')

      expect(response).to have_http_status(:ok)
      rows = table_rows
      expect(rows[client_a.id][1..4]).to eq(['Alpha', 'Allowed', 'Jun 15, 1985', '111-22-3333'])
      expect(rows[client_b.id][1..4]).to eq(['Name Redacted', 'Name Redacted', 'Redacted', 'XXX-XX-6666'])
    end
  end

  context 'with a v5 report' do
    let!(:report) { create(:data_quality_report_version_five, project_group: project_group) }

    it_behaves_like 'a per-project PII policy'
  end

  context 'with a v4 report' do
    let!(:report) { create(:data_quality_report_version_four, project_group: project_group) }

    it_behaves_like 'a per-project PII policy'
  end

  context 'when can_view_clients is granted on only one project in the group' do
    let!(:report) { create(:data_quality_report_version_five, project_group: project_group) }

    before do
      add_dq_row(report: report, client: client_a, project: project_a, ssn: '111223333')
      add_dq_row(report: report, client: client_b, project: project_b, ssn: '444556666')
    end

    it 'lists the row from the other project with its client link and non-PII columns, and redacts its PII' do
      get support_project_group_data_quality_report_path(project_group, report, individual: true, method: 'dob_after_entry')

      expect(response).to have_http_status(:ok)
      rows = table_rows
      expect(rows.keys).to contain_exactly(client_a.id, client_b.id)
      expect(rows[client_b.id][1..4]).to eq(['Name Redacted', 'Name Redacted', 'Redacted', 'XXX-XX-6666'])
      expect(rows[client_b.id][7]).to eq(project_b.ProjectName)
      client_b_link = Nokogiri::HTML(response.body).at_css("table.table-hover tbody a[href='#{destination_source_client_path(client_b.id)}']")
      expect(client_b_link&.text).to eq(client_b.id.to_s)
    end
  end

  context 'when can_view_clients is granted on no project in the group' do
    let!(:report) { create(:data_quality_report_version_five, project_group: project_group) }

    before { add_dq_row(report: report, client: client_b, project: project_b, ssn: '444556666') }

    it 'redirects the drilldown as not authorized' do
      viewer = sign_in_viewer_without_can_view_clients_in_group

      get support_project_group_data_quality_report_path(project_group, report, individual: true, method: 'dob_after_entry')

      expect(response).to redirect_to(viewer.my_root_path)
      expect(flash[:alert]).to eq('Sorry you are not authorized to do that.')
    end
  end

  context 'through a notification token' do
    let!(:report) { create(:data_quality_report_version_five, project_group: project_group) }

    before do
      add_dq_row(report: report, client: client_a, project: project_a, ssn: '111223333')
      add_dq_row(report: report, client: client_b, project: project_b, ssn: '444556666')
    end

    def get_dob_after_entry_with_token(recipient)
      contact = create(:grda_warehouse_contact_project, user: recipient, entity: project_a)
      token = GrdaWarehouse::ReportToken.create!(report_id: report.id, contact_id: contact.id)
      sign_in(recipient)
      get support_notification_project_group_data_quality_report_path(token.token, project_group, report, individual: true, method: 'dob_after_entry')
    end

    it 'applies each row project role for the recipient' do
      get_dob_after_entry_with_token(user)

      expect(response).to have_http_status(:ok)
      rows = table_rows
      expect(rows[client_a.id][1..4]).to eq(['Alpha', 'Allowed', 'Jun 15, 1985', '111-22-3333'])
      expect(rows[client_b.id][1..4]).to eq(['Name Redacted', 'Name Redacted', 'Redacted', 'XXX-XX-6666'])
    end

    it 'redirects a recipient without can_view_clients on any project in the group as not authorized' do
      recipient = create(:acl_user)
      setup_access_control(recipient, role_b, collection_b)

      get_dob_after_entry_with_token(recipient)

      expect(response).to redirect_to(recipient.my_root_path)
      expect(flash[:alert]).to eq('Sorry you are not authorized to do that.')
    end
  end

  describe 'drilldown links on the report page' do
    shared_examples 'drilldown links follow can_view_clients in the group' do
      before { add_dq_row(report: report, client: client_b, project: project_b, ssn: '444556666') }

      it 'renders drilldown links for a user with can_view_clients on a project in the group' do
        get project_group_data_quality_report_path(project_group, report)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(support_project_group_data_quality_report_path(project_group, report))
        expect(response.body).to include('method=dob_after_entry')
      end

      it 'renders no drilldown links or chart drilldown URLs without can_view_clients on a project in the group' do
        sign_in_viewer_without_can_view_clients_in_group

        get project_group_data_quality_report_path(project_group, report)

        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include(support_project_group_data_quality_report_path(project_group, report))
        expect(response.body).not_to include('method=dob_after_entry')
      end
    end

    context 'with a v5 report' do
      let!(:report) { create(:data_quality_report_version_five, project_group: project_group, completed_at: Time.current, requestor_id: user.id) }

      it_behaves_like 'drilldown links follow can_view_clients in the group'
    end

    context 'with a v4 report' do
      let!(:report) { create(:data_quality_report_version_four, project_group: project_group, completed_at: Time.current, requestor_id: user.id) }

      it_behaves_like 'drilldown links follow can_view_clients in the group'
    end
  end

  context 'with a v3 report' do
    def legacy_report_with(headers, row)
      create(:data_quality_report_version_three, project_group: project_group, support: { 'k' => { 'headers' => headers, 'counts' => [row] } })
    end

    it 'denies PII for a stored row with no Project ID' do
      legacy_report = legacy_report_with(['Client ID', 'First Name', 'Last Name'], [client_a.id, 'Alpha', 'Allowed'])

      get support_project_group_data_quality_report_path(project_group, legacy_report, key: 'k')

      expect(response).to have_http_status(:ok)
      expect(table_rows[client_a.id][1..2]).to eq(['Name Redacted', 'Name Redacted'])
    end

    it 'applies the project role for a stored row whose Project ID is a string' do
      legacy_report = legacy_report_with(['Client ID', 'First Name', 'Last Name', 'Project ID'], [client_a.id, 'Alpha', 'Allowed', project_a.id.to_s])

      get support_project_group_data_quality_report_path(project_group, legacy_report, key: 'k')

      expect(table_rows[client_a.id][1..2]).to eq(['Alpha', 'Allowed'])
    end
  end
end
