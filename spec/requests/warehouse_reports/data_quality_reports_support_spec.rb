###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'DataQualityReportsController#support', type: :request do
  let!(:collection) { create(:collection) }
  let(:pii_permissions) { { can_view_client_name: true } }
  let(:can_view_clients) { true }
  let!(:role) { create(:role, can_view_all_reports: true, can_view_assigned_reports: true, can_view_clients: can_view_clients, can_view_projects: true, **pii_permissions) }
  let!(:user) { create(:acl_user) }

  let!(:report_definition) do
    GrdaWarehouse::WarehouseReports::ReportDefinition.create!(
      url: 'warehouse_reports/project/data_quality',
      name: 'Project Data Quality',
      report_group: 'Reports',
      description: 'Project Data Quality',
    )
  end

  let!(:project_data_source) { create(:grda_warehouse_data_source) }
  let!(:organization) { create(:hud_organization, data_source: project_data_source) }
  let!(:project) { create(:hud_project, data_source: project_data_source, OrganizationID: organization.OrganizationID) }
  let!(:report) { create(:data_quality_report_version_five, project: project) }

  let!(:hmis_ds) { create(:hmis_primary_data_source) }
  let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
  let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Restricted', last_name: 'Client') }
  let!(:restricted_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Restricted', LastName: 'Client') }
  let!(:open_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Open', LastName: 'Doe') }

  after { GrdaWarehouse::Config.invalidate_cache }

  def add_dq_row(client:, first_name:, last_name:, dob:, ssn:, **attributes)
    Reporting::DataQualityReports::Enrollment.create!(
      report_id: report.id,
      client_id: client.id,
      project_id: project.id,
      project_name: project.ProjectName,
      enrolled: true,
      dob_after_entry_date: true,
      entry_date: Date.new(2016, 1, 1),
      calculated_at: Time.current,
      first_name: first_name,
      last_name: last_name,
      dob: dob,
      ssn: ssn,
      **attributes,
    )
  end

  def grant_can_view_clients_on_another_project(person)
    other_collection = create(:collection)
    other_collection.set_viewables({ projects: [create(:hud_project).id] })
    setup_access_control(person, create(:role, can_view_clients: true), other_collection)
  end

  def configure_download_toggle(enabled)
    GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: enabled)
    GrdaWarehouse::Config.invalidate_cache
  end

  # Cells for each table row, keyed by the client id in the first cell.
  def table_rows
    Nokogiri::HTML(response.body).css('table.table-hover tbody tr').to_h do |tr|
      cells = tr.css('td').map { |td| td.text.strip }
      [cells.first.to_i, cells]
    end
  end

  def xlsx_rows
    excel_file = Tempfile.new(['data_quality_support', '.xlsx'])
    excel_file.binmode
    excel_file.write(response.body)
    excel_file.close
    sheet = Roo::Excelx.new(excel_file.path).sheet(0)
    (sheet.first_row + 1..sheet.last_row).map { |i| sheet.row(i) }
  ensure
    excel_file&.unlink
  end

  def get_dob_after_entry(format: nil)
    get support_project_data_quality_report_path(project, report, individual: true, method: 'dob_after_entry', format: format)
  end

  before do
    Collection.maintain_system_groups
    collection.set_viewables({ reports: [report_definition.id], projects: [project.id] })
    setup_access_control(user, role, collection)
    GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_destination_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s)
    restricted_source_client.mark_as_restricted!(user: hmis_user)
    sign_in(user)
  end

  context 'with the open client in the report' do
    before { add_dq_row(client: open_destination_client, first_name: 'Open', last_name: 'Doe', dob: Date.new(1985, 6, 15), ssn: '987654321') }

    it 'shows the name, masks the SSN, and hides the DOB when the project role lacks full SSN and DOB' do
      get_dob_after_entry

      expect(response).to have_http_status(:ok)
      expect(table_rows[open_destination_client.id][1..4]).to eq(['Open', 'Doe', 'Redacted', 'XXX-XX-4321'])
    end

    context 'when the project role grants full SSN and DOB' do
      let(:pii_permissions) { { can_view_client_name: true, can_view_full_ssn: true, can_view_full_dob: true } }

      it 'shows the full DOB and SSN' do
        get_dob_after_entry

        expect(table_rows[open_destination_client.id][1..4]).to eq(['Open', 'Doe', 'Jun 15, 1985', '987-65-4321'])
      end
    end

    context 'when the project role lacks can_view_client_name' do
      let(:pii_permissions) { {} }

      it 'redacts the name' do
        get_dob_after_entry

        expect(table_rows[open_destination_client.id][1..2]).to eq(['Name Redacted', 'Name Redacted'])
      end
    end

    context 'through a notification token' do
      def get_dob_after_entry_with_token(recipient)
        contact = create(:grda_warehouse_contact_project, user: recipient, entity: project)
        token = GrdaWarehouse::ReportToken.create!(report_id: report.id, contact_id: contact.id)
        sign_in(recipient)
        get support_notification_project_data_quality_report_path(token.token, project, report, individual: true, method: 'dob_after_entry')
      end

      it 'redacts PII for a recipient whose project role grants no PII permissions' do
        recipient = create(:acl_user)
        recipient_collection = create(:collection)
        recipient_collection.set_viewables({ projects: [project.id] })
        setup_access_control(recipient, create(:role, can_view_clients: true), recipient_collection)

        get_dob_after_entry_with_token(recipient)

        expect(response).to have_http_status(:ok)
        expect(table_rows[open_destination_client.id][1..4]).to eq(['Name Redacted', 'Name Redacted', 'Redacted', 'XXX-XX-4321'])
      end

      it 'applies the project role for a recipient who has one' do
        get_dob_after_entry_with_token(user)

        expect(response).to have_http_status(:ok)
        expect(table_rows[open_destination_client.id][1..4]).to eq(['Open', 'Doe', 'Redacted', 'XXX-XX-4321'])
      end

      it 'redirects a recipient without can_view_clients on the report project as not authorized' do
        recipient = create(:acl_user)
        recipient_collection = create(:collection)
        recipient_collection.set_viewables({ projects: [project.id] })
        setup_access_control(recipient, create(:role, can_view_projects: true), recipient_collection)
        grant_can_view_clients_on_another_project(recipient)

        get_dob_after_entry_with_token(recipient)

        expect(response).to redirect_to(recipient.my_root_path)
        expect(flash[:alert]).to eq('Sorry you are not authorized to do that.')
      end
    end

    context 'in the Excel export' do
      it 'applies the project role when include_pii_in_detail_downloads is on' do
        configure_download_toggle(true)

        get_dob_after_entry(format: :xlsx)

        expect(response).to have_http_status(:ok)
        open_row = xlsx_rows.find { |r| r[0] == open_destination_client.id }
        expect(open_row[1..4]).to eq(['Open', 'Doe', 'Redacted', 'XXX-XX-4321'])
      end

      it 'redacts every client when include_pii_in_detail_downloads is off' do
        configure_download_toggle(false)

        get_dob_after_entry(format: :xlsx)

        open_row = xlsx_rows.find { |r| r[0] == open_destination_client.id }
        expect(open_row[1..4]).to eq(['Name Redacted', 'Name Redacted', 'Redacted', 'Redacted'])
      end
    end
  end

  context 'when the project role grants every PII permission' do
    let(:pii_permissions) { { can_view_client_name: true, can_view_full_ssn: true, can_view_full_dob: true } }

    before do
      add_dq_row(client: restricted_destination_client, first_name: 'Restricted', last_name: 'Client', dob: Date.new(1990, 1, 1), ssn: '123456789')
      add_dq_row(client: open_destination_client, first_name: 'Open', last_name: 'Doe', dob: Date.new(1985, 6, 15), ssn: '987654321')
    end

    it 'still redacts the restricted client' do
      get_dob_after_entry

      rows = table_rows
      expect(rows[restricted_destination_client.id][1..4]).to eq(['Name Redacted', 'Name Redacted', 'Redacted', 'Redacted'])
      expect(rows[open_destination_client.id][1..4]).to eq(['Open', 'Doe', 'Jun 15, 1985', '987-65-4321'])
    end
  end

  context 'with a v3 report' do
    let!(:legacy_report) do
      create(
        :data_quality_report_version_three,
        project: project,
        support: {
          'ssn' => {
            'headers' => ['Client ID', 'First Name', 'Last Name', 'SSN', 'SSN Quality'],
            'counts' => [[open_destination_client.id, 'Open', 'Doe', '987654321', 1]],
          },
        },
      )
    end

    it 'applies the project role to the stored drilldown' do
      get support_project_data_quality_report_path(project, legacy_report, key: 'ssn')

      expect(response).to have_http_status(:ok)
      expect(table_rows[open_destination_client.id][1..3]).to eq(['Open', 'Doe', 'XXX-XX-4321'])
    end

    it 'redacts the stored drilldown Excel export when include_pii_in_detail_downloads is off' do
      configure_download_toggle(false)

      get support_project_data_quality_report_path(project, legacy_report, key: 'ssn', format: :xlsx)

      expect(response).to have_http_status(:ok)
      expect(xlsx_rows).to eq([[open_destination_client.id, 'Name Redacted', 'Name Redacted', 'Redacted', 1]])
    end

    it 'returns 404 for the support dump without a key' do
      get support_project_data_quality_report_path(project, legacy_report)

      expect(response).to have_http_status(:not_found)
      expect(response.body).not_to include('Open')
    end
  end

  context 'with the project completeness drilldown' do
    let!(:complete_client) { create(:grda_warehouse_hud_client, FirstName: 'Complete', LastName: 'Record') }

    it 'lists only the rows missing an SSN, with the SSN masked' do
      add_dq_row(client: open_destination_client, first_name: 'Open', last_name: 'Doe', dob: Date.new(1985, 6, 15), ssn: '987654321', ssn_missing: true)
      add_dq_row(client: complete_client, first_name: 'Complete', last_name: 'Record', dob: Date.new(1985, 6, 15), ssn: '111223333', ssn_missing: false)

      get support_project_data_quality_report_path(
        project,
        report,
        individual: true,
        method: 'project_completeness',
        column: 'ssn',
        metric: 'missing',
        selected_project_id: project.id.to_s,
      )

      expect(response).to have_http_status(:ok)
      rows = table_rows
      expect(rows.keys).to eq([open_destination_client.id])
      expect(rows[open_destination_client.id][4]).to eq('XXX-XX-4321')
    end
  end

  context 'when can_view_clients is granted only on another project' do
    let(:can_view_clients) { false }

    before do
      grant_can_view_clients_on_another_project(user)
      add_dq_row(client: open_destination_client, first_name: 'Open', last_name: 'Doe', dob: Date.new(1985, 6, 15), ssn: '987654321')
    end

    it 'redirects the drilldown as not authorized' do
      get_dob_after_entry

      expect(response).to redirect_to(user.my_root_path)
      expect(flash[:alert]).to eq('Sorry you are not authorized to do that.')
    end

    it 'redirects a v3 stored drilldown as not authorized' do
      legacy_report = create(
        :data_quality_report_version_three,
        project: project,
        support: { 'ssn' => { 'headers' => ['Client ID', 'First Name'], 'counts' => [[open_destination_client.id, 'Open']] } },
      )

      get support_project_data_quality_report_path(project, legacy_report, key: 'ssn')

      expect(response).to redirect_to(user.my_root_path)
    end
  end

  describe 'drilldown links on the report page' do
    shared_examples 'drilldown links follow can_view_clients' do
      before { add_dq_row(client: open_destination_client, first_name: 'Open', last_name: 'Doe', dob: Date.new(1985, 6, 15), ssn: '987654321') }

      it 'renders drilldown links for a user with can_view_clients' do
        get project_data_quality_report_path(project, report)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(support_project_data_quality_report_path(project, report))
        expect(response.body).to include('method=dob_after_entry')
      end

      context 'when can_view_clients is granted only on another project' do
        let(:can_view_clients) { false }

        before { grant_can_view_clients_on_another_project(user) }

        it 'renders no drilldown links or chart drilldown URLs' do
          get project_data_quality_report_path(project, report)

          expect(response).to have_http_status(:ok)
          expect(response.body).not_to include(support_project_data_quality_report_path(project, report))
          expect(response.body).not_to include('method=dob_after_entry')
        end
      end
    end

    context 'with a v5 report' do
      let!(:report) { create(:data_quality_report_version_five, project: project, completed_at: Time.current, requestor_id: user.id) }

      it_behaves_like 'drilldown links follow can_view_clients'
    end

    context 'with a v4 report' do
      let!(:report) { create(:data_quality_report_version_four, project: project, completed_at: Time.current, requestor_id: user.id) }

      it_behaves_like 'drilldown links follow can_view_clients'
    end
  end

  context 'with more clients than the preload miss threshold' do
    let!(:extra_clients) do
      Array.new(preload_miss_client_count) { |i| create(:grda_warehouse_hud_client, FirstName: "Preload#{i}", LastName: 'Coverage') }
    end

    before do
      extra_clients.each { |c| add_dq_row(client: c, first_name: c.FirstName, last_name: c.LastName, dob: Date.new(1990, 1, 1), ssn: '123456789') }
    end

    it 'lists every client in the HTML view' do
      get_dob_after_entry

      expect(response).to have_http_status(:ok)
      expect(table_rows.transform_values { |cells| cells[1] }).to eq(extra_clients.to_h { |c| [c.id, c.FirstName] })
    end
  end
end
