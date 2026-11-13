###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# The controller renders the filter page and nothing else -- the XLSX is built by
# GrdaWarehouse::WarehouseReports::DocumentExports::ClientLookupExport in a background
# job (see spec/requests/warehouse_reports/client_lookup_export_spec.rb for the report's
# rows, PII redaction, and project scoping).
RSpec.describe WarehouseReports::ClientLookupsController, type: :request do
  include AccessControlSetup

  let(:source_ds) { create(:source_data_source) }
  let(:organization) { create(:hud_organization, data_source_id: source_ds.id) }
  let!(:viewable_project) do
    create(
      :hud_project,
      data_source_id: source_ds.id,
      OrganizationID: organization.OrganizationID,
      confidential: false,
    )
  end

  let(:user) { create(:acl_user) }
  let(:role) { create(:role, can_view_assigned_reports: true) }
  let(:collection) { create(:collection) }
  let!(:report_definition) { create(:client_lookups_report) }
  let(:viewable_reports) { [report_definition.id] }

  before do
    collection.set_viewables(reports: viewable_reports, projects: [viewable_project.id])
    setup_access_control(user, role, collection)
    sign_in(user)
  end

  describe 'GET #index' do
    it 'renders the filter page' do
      get warehouse_reports_client_lookups_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include('Export Client Personal ID Lookup')
    end

    it 'renders a download button wired to the export class' do
      get warehouse_reports_client_lookups_path

      expect(response.body).to include('j-document-exports')
      expect(response.body).to include('GrdaWarehouse::WarehouseReports::DocumentExports::ClientLookupExport')
    end

    it 'mounts the client-lookup-export controller on the filter form' do
      get warehouse_reports_client_lookups_path

      # Rails' form helper and Haml's literal attributes quote differently, so match on
      # the attribute values rather than a quoting style.
      body = CGI.unescapeHTML(response.body).tr('"', "'")

      expect(body).to include("data-controller='client-lookup-export'")
      expect(body).to include("data-action='client-lookup-export#download'")
      expect(body).to include("data-client-lookup-export-target='button'")
    end

    # The controller renders its message into the layout's flash region rather than a
    # container of its own, so the page has to actually provide one.
    it 'renders inside the layout flash region' do
      get warehouse_reports_client_lookups_path

      expect(response.body).to include('utility')
    end

    # The export reconstructs the filter from a query string built off this form at click
    # time, so a query string rendered into the page would be stale by definition.
    it 'does not render a query string on the button' do
      get warehouse_reports_client_lookups_path

      expect(response.body).not_to include('data-query-string')
    end

    # The removed synchronous path redirected with this message when nothing was
    # selected; the disabled button can't deliver it on click, so the wrapper carries it
    # as a tooltip the Stimulus controller enables while the filter has no scope.
    it 'wraps the button in a tooltip explaining the requirement' do
      get warehouse_reports_client_lookups_path

      wrapper = response.body[/<span[^>]*client-lookup-export-target[^>]*>/]

      expect(wrapper).to match(/title=.Select at least one Data Source, Organization, or Project/)
    end

    # Rendered disabled up front so the state is correct before the Stimulus controller
    # connects, rather than flashing enabled on load.
    it 'ships the download button disabled when the filter has no project scope' do
      get warehouse_reports_client_lookups_path

      button = response.body[/<a[^>]*j-document-exports[^>]*>/]

      expect(button).to include('disabled')
      expect(button).to include('aria-disabled')
    end

    it 'ships the download button enabled once a project is selected' do
      get warehouse_reports_client_lookups_path, params: { report: { project_ids: [viewable_project.id] } }

      button = response.body[/<a[^>]*j-document-exports[^>]*>/]

      # Haml omits a false-valued attribute entirely, so an enabled button carries no
      # `aria-disabled` rather than `aria-disabled='false'`.
      expect(button).not_to include('disabled')
    end

    it 'keeps the Map Enrollment IDs checkbox checked when it was submitted' do
      get warehouse_reports_client_lookups_path, params: { report: { map_enrollments: '1' } }

      expect(response.body).to match(/name=.report\[map_enrollments\].[^>]*checked/)
    end
  end

  # Regression guards on `WarehouseReportAuthorization`, which is the only authorization
  # the page itself enforces. The export re-checks both before running, but a user who
  # cannot see the report should not reach the form in the first place.
  describe 'authorization' do
    context 'when the user cannot view any reports' do
      let(:role) { create(:role, can_view_assigned_reports: false) }

      it 'refuses to render the page' do
        get warehouse_reports_client_lookups_path

        expect(response).to have_http_status(:redirect)
      end
    end

    context 'when the report is not viewable by the user' do
      let(:viewable_reports) { [] }

      it 'refuses to render the page' do
        get warehouse_reports_client_lookups_path

        expect(response).to have_http_status(:redirect)
      end
    end
  end
end
