###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'roo'

# Baseline coverage for the Client PersonalID Lookup (Client Lookups) crosswalk report.
#
# This report renders a 5-column XLSX (Data Source, PersonalID, warehouse destination
# Client ID, FirstName, LastName) for source clients enrolled in a selected set of
# projects during a date range, with two additional columns (Enrollment ID, Warehouse
# Enrollment ID) when "Map enrollments" is checked. See
# app/controllers/warehouse_reports/client_lookups_controller.rb and
# app/models/warehouse_reports/client_lookups/report.rb.
#
# The report scopes its project filter through `Project.viewable_by(current_user,
# permission: :can_view_assigned_reports)` (see `Report#project_source`), the way
# sibling reports (e.g. EntryExitServiceController) do. The "project-level
# authorization" and "confidential project" groups below are regression guards for that
# scoping: they submit project ids the user was never granted, or that are
# confidential, and assert the resulting rows exclude them. All groups in this file are
# expected to stay green; a regression in `project_source` or its `merge` into the
# report query should turn one of these red.
RSpec.describe WarehouseReports::ClientLookupsController, type: :request do
  include AccessControlSetup

  before(:all) do
    # Other specs leak warehouse data that would break our row assertions.
    GrdaWarehouse::Utility.clear!
  end

  after(:all) do
    GrdaWarehouse::Utility.clear!
  end

  let(:start_date) { Date.new(2023, 1, 1) }
  let(:end_date) { Date.new(2023, 12, 31) }

  # A "source" data source holds the as-imported HMIS client/enrollment records the
  # report queries; the "destination" data source holds the deduplicated warehouse
  # identity that supplies the destination_id column.
  let!(:source_ds) { create(:source_data_source) }
  let!(:destination_ds) { create(:destination_data_source) }

  let(:organization) { create(:hud_organization, data_source_id: source_ds.id) }

  let!(:viewable_project) do
    create(
      :hud_project,
      data_source_id: source_ds.id,
      OrganizationID: organization.OrganizationID,
      confidential: false,
    )
  end

  let!(:unauthorized_project) do
    create(
      :hud_project,
      data_source_id: source_ds.id,
      OrganizationID: organization.OrganizationID,
      confidential: false,
    )
  end

  # Project the user is allowed to see, but which is flagged confidential.
  let!(:confidential_project) do
    create(
      :hud_project,
      data_source_id: source_ds.id,
      OrganizationID: organization.OrganizationID,
      confidential: true,
    )
  end

  let(:user) { create(:acl_user) }
  let(:role) { create(:role, can_view_assigned_reports: true, can_view_client_name: true) }
  let(:collection) { create(:collection) }
  let!(:report_definition) { create(:client_lookups_report) }

  before do
    # Grant report visibility and access to the two "authorized" projects
    # (viewable_project + confidential_project), but NOT unauthorized_project.
    collection.set_viewables(
      reports: [report_definition.id],
      projects: [viewable_project.id, confidential_project.id],
    )
    setup_access_control(user, role, collection)
    sign_in(user)
  end

  # Build the full crosswalk graph (source client -> warehouse client -> destination
  # client, plus an enrollment in `project`) and return the destination (warehouse) id
  # and the created enrollment, since some tests need the enrollment's HUD/DB ids too.
  def create_crosswalk(project:, personal_id:, first_name:, last_name:, entry_date: start_date + 1.day, data_source: source_ds)
    source_client = create(
      :grda_warehouse_hud_client,
      data_source: data_source,
      PersonalID: personal_id,
      FirstName: first_name,
      LastName: last_name,
    )
    destination_client = create(:grda_warehouse_hud_client, data_source: destination_ds)
    create(
      :warehouse_client,
      source: source_client,
      destination: destination_client,
      data_source: data_source,
    )
    enrollment = create(
      :grda_warehouse_hud_enrollment,
      data_source_id: data_source.id,
      PersonalID: personal_id,
      ProjectID: project.ProjectID,
      EntryDate: entry_date,
    )
    { destination_id: destination_client.id, enrollment: enrollment }
  end

  def get_report(project_ids:, map_enrollments: false, data_source_ids: [source_ds.id], organization_ids: [])
    get(
      warehouse_reports_client_lookups_path(format: :xlsx),
      params: {
        report: {
          start: start_date,
          end: end_date,
          project_ids: project_ids,
          organization_ids: organization_ids,
          data_source_ids: data_source_ids,
          map_enrollments: map_enrollments ? '1' : '0',
        },
      },
    )
  end

  # The report plucks [Data Source name, PersonalID, destination_id, FirstName,
  # LastName, ...]; pull out just the warehouse (destination) ids so we can assert
  # which clients were included.
  def reported_destination_ids
    assigns(:report).rows.map { |row| row[2] }
  end

  # Parse the actual rendered XLSX response body (not the controller's @rows ivar) so
  # tests can catch bugs in Report#to_xlsx itself, e.g. a wrong header, dropped column,
  # or reordered fields that assigns(:rows)-only assertions would miss entirely.
  def rendered_workbook_rows
    excel_file = Tempfile.new(['client_lookups', '.xlsx'])
    begin
      excel_file.binmode
      excel_file.write(response.body)
      excel_file.close

      spreadsheet = Roo::Excelx.new(excel_file.path)
      sheet = spreadsheet.sheet(0)
      (1..sheet.last_row).map { |i| sheet.row(i) }
    ensure
      excel_file.unlink
    end
  end

  describe 'current behavior (should remain green)' do
    it 'includes a client enrolled in an allowed project during the range' do
      destination_id = create_crosswalk(
        project: viewable_project,
        personal_id: 'PID-VIEWABLE',
        first_name: 'Ada',
        last_name: 'Lovelace',
      ).fetch(:destination_id)

      get_report(project_ids: [viewable_project.id])

      expect(response).to have_http_status(:success)
      expect(reported_destination_ids).to include(destination_id)
      expect(assigns(:report).rows).to include([source_ds.name, 'PID-VIEWABLE', destination_id, 'Ada', 'Lovelace'])
    end
  end

  describe 'date range boundary (regression guard)' do
    it 'includes an enrollment whose EntryDate falls exactly on the end of the range' do
      destination_id = create_crosswalk(
        project: viewable_project,
        personal_id: 'PID-ENTRY-ON-END',
        first_name: 'Rosalind',
        last_name: 'Franklin',
        entry_date: end_date,
      ).fetch(:destination_id)

      get_report(project_ids: [viewable_project.id])

      expect(response).to have_http_status(:success)
      expect(reported_destination_ids).to include(destination_id)
    end

    it 'excludes an enrollment whose EntryDate falls one day after the end of the range' do
      destination_id = create_crosswalk(
        project: viewable_project,
        personal_id: 'PID-ENTRY-AFTER-END',
        first_name: 'Marie',
        last_name: 'Curie',
        entry_date: end_date + 1.day,
      ).fetch(:destination_id)

      get_report(project_ids: [viewable_project.id])

      expect(response).to have_http_status(:success)
      expect(reported_destination_ids).not_to include(destination_id)
    end

    it 'includes an enrollment that exited exactly on the start of the range' do
      crosswalk = create_crosswalk(
        project: viewable_project,
        personal_id: 'PID-EXIT-ON-START',
        first_name: 'Rosalind',
        last_name: 'Franklin',
        entry_date: start_date - 30.days,
      )
      create(
        :hud_exit,
        data_source: source_ds,
        EnrollmentID: crosswalk.fetch(:enrollment).EnrollmentID,
        PersonalID: 'PID-EXIT-ON-START',
        ExitDate: start_date,
      )

      get_report(project_ids: [viewable_project.id])

      expect(response).to have_http_status(:success)
      expect(reported_destination_ids).to include(crosswalk.fetch(:destination_id))
    end

    it 'excludes an enrollment that exited one day before the start of the range' do
      crosswalk = create_crosswalk(
        project: viewable_project,
        personal_id: 'PID-EXIT-BEFORE-START',
        first_name: 'Marie',
        last_name: 'Curie',
        entry_date: start_date - 30.days,
      )
      create(
        :hud_exit,
        data_source: source_ds,
        EnrollmentID: crosswalk.fetch(:enrollment).EnrollmentID,
        PersonalID: 'PID-EXIT-BEFORE-START',
        ExitDate: start_date - 1.day,
      )

      get_report(project_ids: [viewable_project.id])

      expect(response).to have_http_status(:success)
      expect(reported_destination_ids).not_to include(crosswalk.fetch(:destination_id))
    end
  end

  describe 'rendered file (regression guard)' do
    it 'writes the header row and client data into the actual XLSX output' do
      destination_id = create_crosswalk(
        project: viewable_project,
        personal_id: 'PID-VIEWABLE',
        first_name: 'Ada',
        last_name: 'Lovelace',
      ).fetch(:destination_id)

      get_report(project_ids: [viewable_project.id])

      rows = rendered_workbook_rows
      expect(rows.first).to eq(
        ['Data Source', 'Personal ID (from HMIS)', 'Warehouse Client ID', 'First Name (from HMIS)', 'Last Name (from HMIS)'],
      )
      expect(rows[1..]).to include([source_ds.name, 'PID-VIEWABLE', destination_id, 'Ada', 'Lovelace'])
    end

    it 'writes the additional enrollment columns when "Map enrollments" is requested' do
      crosswalk = create_crosswalk(
        project: viewable_project,
        personal_id: 'PID-VIEWABLE',
        first_name: 'Ada',
        last_name: 'Lovelace',
      )

      get_report(project_ids: [viewable_project.id], map_enrollments: true)

      rows = rendered_workbook_rows
      expect(rows.first).to eq(
        [
          'Data Source', 'Personal ID (from HMIS)', 'Warehouse Client ID', 'First Name (from HMIS)', 'Last Name (from HMIS)',
          'Enrollment ID (from HMIS)', 'Warehouse Enrollment ID'
        ],
      )
      # Roo reads a numeric-looking string cell (EnrollmentID) back as a Numeric, not a
      # String, so compare it numerically rather than against the pluck'd String value.
      expect(rows[1..]).to include(
        [
          source_ds.name, 'PID-VIEWABLE', crosswalk.fetch(:destination_id), 'Ada', 'Lovelace',
          crosswalk.fetch(:enrollment).EnrollmentID.to_i, crosswalk.fetch(:enrollment).id
        ],
      )
    end
  end

  describe 'report-level authorization (should remain green)' do
    let(:role) { create(:role, can_view_assigned_reports: false) }

    it 'refuses to render the report for a user who cannot view any reports' do
      get_report(project_ids: [viewable_project.id])

      expect(response).to have_http_status(:redirect)
    end
  end

  describe 'project-level authorization (regression guard)' do
    it 'excludes clients whose only enrollment is in a project the user cannot view, even when its id is submitted' do
      allowed_destination_id = create_crosswalk(
        project: viewable_project,
        personal_id: 'PID-ALLOWED',
        first_name: 'Ada',
        last_name: 'Lovelace',
      ).fetch(:destination_id)
      forbidden_destination_id = create_crosswalk(
        project: unauthorized_project,
        personal_id: 'PID-FORBIDDEN',
        first_name: 'Mallory',
        last_name: 'Malicious',
      ).fetch(:destination_id)

      # A user can hand-craft the params and submit a project id they were never granted.
      get_report(project_ids: [viewable_project.id, unauthorized_project.id])

      expect(response).to have_http_status(:success)
      expect(reported_destination_ids).to include(allowed_destination_id)
      expect(reported_destination_ids).not_to include(forbidden_destination_id)
    end

    it 'redirects with a clear message instead of silently exporting nothing when the only selected project is unauthorized' do
      # Regression guard: previously a single unauthorized (but hand-craftable) project
      # id would pass `any_effective_project_ids?` (which doesn't check authorization)
      # and then silently produce a zero-row export via the `project_source` merge.
      get_report(project_ids: [unauthorized_project.id], data_source_ids: [])

      expect(response).to have_http_status(:redirect)
      expect(response.location).to include("project_ids%5D%5B%5D=#{unauthorized_project.id}")
      expect(flash[:alert]).to eq('you do not have permission to view the selected project(s) for this report')
    end

    it 'excludes clients from a project the user can view but did not select in the filter' do
      # A second non-confidential project the user is granted access to via their
      # collection, distinct from viewable_project (which is the only one selected below).
      other_viewable_project = create(
        :hud_project,
        data_source_id: source_ds.id,
        OrganizationID: organization.OrganizationID,
        confidential: false,
      )
      collection.set_viewables(
        reports: [report_definition.id],
        projects: [viewable_project.id, confidential_project.id, other_viewable_project.id],
      )

      selected_destination_id = create_crosswalk(
        project: viewable_project,
        personal_id: 'PID-SELECTED',
        first_name: 'Ada',
        last_name: 'Lovelace',
      ).fetch(:destination_id)
      unselected_destination_id = create_crosswalk(
        project: other_viewable_project,
        personal_id: 'PID-UNSELECTED-BUT-VIEWABLE',
        first_name: 'Not',
        last_name: 'Selected',
      ).fetch(:destination_id)

      # Only viewable_project is selected in the filter (data_source_ids/organization_ids
      # are cleared so effective_project_ids comes purely from project_ids), even though
      # other_viewable_project is also granted to the user. The project_source (viewable_by)
      # merge must not silently widen the query back out to every project the user can view.
      get_report(project_ids: [viewable_project.id], data_source_ids: [])

      expect(response).to have_http_status(:success)
      expect(reported_destination_ids).to include(selected_destination_id)
      expect(reported_destination_ids).not_to include(unselected_destination_id)
    end
  end

  describe 'confidential project exclusion (regression guard)' do
    it 'excludes clients whose only enrollment is in a confidential project' do
      allowed_destination_id = create_crosswalk(
        project: viewable_project,
        personal_id: 'PID-ALLOWED',
        first_name: 'Ada',
        last_name: 'Lovelace',
      ).fetch(:destination_id)
      confidential_destination_id = create_crosswalk(
        project: confidential_project,
        personal_id: 'PID-CONFIDENTIAL',
        first_name: 'Secret',
        last_name: 'Client',
      ).fetch(:destination_id)

      get_report(project_ids: [viewable_project.id, confidential_project.id])

      expect(response).to have_http_status(:success)
      expect(reported_destination_ids).to include(allowed_destination_id)
      expect(reported_destination_ids).not_to include(confidential_destination_id)
    end

    it 'excludes clients whose only enrollment is in a non-confidential project of a confidential organization' do
      confidential_org = create(:hud_organization, data_source_id: source_ds.id, confidential: true)
      org_confidential_project = create(
        :hud_project,
        data_source_id: source_ds.id,
        OrganizationID: confidential_org.OrganizationID,
        confidential: false,
      )
      collection.set_viewables(
        reports: [report_definition.id],
        projects: [viewable_project.id, confidential_project.id, org_confidential_project.id],
      )

      allowed_destination_id = create_crosswalk(
        project: viewable_project,
        personal_id: 'PID-ALLOWED',
        first_name: 'Ada',
        last_name: 'Lovelace',
      ).fetch(:destination_id)
      org_confidential_destination_id = create_crosswalk(
        project: org_confidential_project,
        personal_id: 'PID-ORG-CONFIDENTIAL',
        first_name: 'Org',
        last_name: 'Secret',
      ).fetch(:destination_id)

      get_report(project_ids: [viewable_project.id, org_confidential_project.id])

      expect(response).to have_http_status(:success)
      expect(reported_destination_ids).to include(allowed_destination_id)
      expect(reported_destination_ids).not_to include(org_confidential_destination_id)
    end
  end

  describe 'source data source disambiguation (regression guard)' do
    it 'does not conflate clients with the same PersonalID from different source data sources' do
      other_source_ds = create(:source_data_source, name: 'Other HMIS Vendor')
      other_organization = create(:hud_organization, data_source_id: other_source_ds.id)
      other_project = create(
        :hud_project,
        data_source_id: other_source_ds.id,
        OrganizationID: other_organization.OrganizationID,
        confidential: false,
      )
      collection.set_viewables(
        reports: [report_definition.id],
        projects: [viewable_project.id, confidential_project.id, other_project.id],
      )

      # HUD PersonalID is only unique within a data source; the same PersonalID here
      # identifies two different people in two different source data sources. The Data
      # Source column is what lets the export disambiguate them.
      destination_id_a = create_crosswalk(
        project: viewable_project,
        personal_id: 'DUPLICATE-PID',
        first_name: 'Ada',
        last_name: 'Lovelace',
      ).fetch(:destination_id)
      destination_id_b = create_crosswalk(
        project: other_project,
        personal_id: 'DUPLICATE-PID',
        first_name: 'Grace',
        last_name: 'Hopper',
        data_source: other_source_ds,
      ).fetch(:destination_id)

      get_report(project_ids: [viewable_project.id, other_project.id])

      expect(response).to have_http_status(:success)
      expect(destination_id_a).not_to eq(destination_id_b)
      expect(assigns(:report).rows).to include([source_ds.name, 'DUPLICATE-PID', destination_id_a, 'Ada', 'Lovelace'])
      expect(assigns(:report).rows).to include([other_source_ds.name, 'DUPLICATE-PID', destination_id_b, 'Grace', 'Hopper'])
    end
  end

  describe 'duplicate enrollments (regression guard)' do
    it 'includes a client only once when they have overlapping enrollments in two allowed projects' do
      second_viewable_project = create(
        :hud_project,
        data_source_id: source_ds.id,
        OrganizationID: organization.OrganizationID,
        confidential: false,
      )
      collection.set_viewables(
        reports: [report_definition.id],
        projects: [viewable_project.id, confidential_project.id, second_viewable_project.id],
      )

      destination_id = create_crosswalk(
        project: viewable_project,
        personal_id: 'PID-DOUBLE-ENROLLED',
        first_name: 'Ada',
        last_name: 'Lovelace',
      ).fetch(:destination_id)
      # A second enrollment for the same source client, in the other allowed project.
      create(
        :grda_warehouse_hud_enrollment,
        data_source_id: source_ds.id,
        PersonalID: 'PID-DOUBLE-ENROLLED',
        ProjectID: second_viewable_project.ProjectID,
        EntryDate: start_date + 1.day,
      )

      get_report(project_ids: [viewable_project.id, second_viewable_project.id])

      expect(response).to have_http_status(:success)
      expect(reported_destination_ids.count { |id| id == destination_id }).to eq(1)
    end
  end

  describe 'deduplicated identity with multiple PersonalIDs (regression guard)' do
    it 'emits one row per PersonalID (not per enrollment) when two source records in the same data source share a warehouse client and name' do
      # Two source client records in the SAME data source, deduplicated to a SINGLE
      # warehouse (destination) client, sharing first/last name but differing only by
      # PersonalID. Grouping in Report#build_rows relies on rows sharing a display_key
      # sorting contiguously; if PersonalID is missing from the query's ORDER BY, these
      # rows interleave by enrollment id and the client is emitted as duplicate rows.
      destination_client = create(:grda_warehouse_hud_client, data_source: destination_ds)

      source_client_a = create(
        :grda_warehouse_hud_client,
        data_source: source_ds,
        PersonalID: 'PID-DEDUP-A',
        FirstName: 'Ada',
        LastName: 'Lovelace',
      )
      source_client_b = create(
        :grda_warehouse_hud_client,
        data_source: source_ds,
        PersonalID: 'PID-DEDUP-B',
        FirstName: 'Ada',
        LastName: 'Lovelace',
      )
      create(:warehouse_client, source: source_client_a, destination: destination_client, data_source: source_ds)
      create(:warehouse_client, source: source_client_b, destination: destination_client, data_source: source_ds)

      # Interleave enrollment creation so their (auto-incrementing) warehouse enrollment
      # ids alternate between the two PersonalIDs. Without PersonalID in the ORDER BY the
      # rows come back A, B, A, B — non-contiguous groups that flush as four rows.
      ['PID-DEDUP-A', 'PID-DEDUP-B', 'PID-DEDUP-A', 'PID-DEDUP-B'].each do |personal_id|
        create(
          :grda_warehouse_hud_enrollment,
          data_source_id: source_ds.id,
          PersonalID: personal_id,
          ProjectID: viewable_project.ProjectID,
          EntryDate: start_date + 1.day,
        )
      end

      get_report(project_ids: [viewable_project.id])

      expect(response).to have_http_status(:success)
      dedup_rows = assigns(:report).rows.select { |row| row[2] == destination_client.id }
      expect(dedup_rows.length).to eq(2)
      expect(dedup_rows.map { |row| row[1] }).to contain_exactly('PID-DEDUP-A', 'PID-DEDUP-B')
    end
  end

  describe 'map enrollments (regression guard)' do
    it 'omits the enrollment columns by default' do
      create_crosswalk(
        project: viewable_project,
        personal_id: 'PID-VIEWABLE',
        first_name: 'Ada',
        last_name: 'Lovelace',
      )

      get_report(project_ids: [viewable_project.id])

      expect(response).to have_http_status(:success)
      expect(assigns(:report).headers).to eq(
        ['Data Source', 'Personal ID (from HMIS)', 'Warehouse Client ID', 'First Name (from HMIS)', 'Last Name (from HMIS)'],
      )
      expect(assigns(:report).rows.first.length).to eq(5)
    end

    it 'adds the Enrollment ID and Warehouse Enrollment ID columns when requested, one row per enrollment' do
      crosswalk = create_crosswalk(
        project: viewable_project,
        personal_id: 'PID-VIEWABLE',
        first_name: 'Ada',
        last_name: 'Lovelace',
      )
      second_viewable_project = create(
        :hud_project,
        data_source_id: source_ds.id,
        OrganizationID: organization.OrganizationID,
        confidential: false,
      )
      collection.set_viewables(
        reports: [report_definition.id],
        projects: [viewable_project.id, confidential_project.id, second_viewable_project.id],
      )
      # A second enrollment for the same source client, in another allowed project;
      # "no dedup" means this must yield a second row, not collapse into one.
      second_enrollment = create(
        :grda_warehouse_hud_enrollment,
        data_source_id: source_ds.id,
        PersonalID: 'PID-VIEWABLE',
        ProjectID: second_viewable_project.ProjectID,
        EntryDate: start_date + 1.day,
      )

      get_report(project_ids: [viewable_project.id, second_viewable_project.id], map_enrollments: true)

      expect(response).to have_http_status(:success)
      expect(assigns(:report).headers).to eq(
        [
          'Data Source', 'Personal ID (from HMIS)', 'Warehouse Client ID', 'First Name (from HMIS)', 'Last Name (from HMIS)',
          'Enrollment ID (from HMIS)', 'Warehouse Enrollment ID'
        ],
      )
      rows = assigns(:report).rows
      expect(rows).to include(
        [
          source_ds.name, 'PID-VIEWABLE', crosswalk.fetch(:destination_id), 'Ada', 'Lovelace',
          crosswalk.fetch(:enrollment).EnrollmentID, crosswalk.fetch(:enrollment).id
        ],
      )
      expect(rows).to include(
        [
          source_ds.name, 'PID-VIEWABLE', crosswalk.fetch(:destination_id), 'Ada', 'Lovelace',
          second_enrollment.EnrollmentID, second_enrollment.id
        ],
      )
      expect(rows.count { |row| row[2] == crosswalk.fetch(:destination_id) }).to eq(2)
    end
  end

  describe 'filter requirement (regression guard)' do
    it 'refuses to render the xlsx when no project, organization, or data source is selected' do
      create_crosswalk(
        project: viewable_project,
        personal_id: 'PID-VIEWABLE',
        first_name: 'Ada',
        last_name: 'Lovelace',
      )

      get_report(project_ids: [], data_source_ids: [], organization_ids: [])

      expect(response).to have_http_status(:redirect)
      follow_redirect!
      expect(response.body).to include('Data Source')
    end

    it 'renders the xlsx when a project is selected without a data source' do
      create_crosswalk(
        project: viewable_project,
        personal_id: 'PID-VIEWABLE',
        first_name: 'Ada',
        last_name: 'Lovelace',
      )

      get_report(project_ids: [viewable_project.id], data_source_ids: [])

      expect(response).to have_http_status(:success)
    end
  end

  describe 'client name PII policy (regression guard)' do
    let(:role) { create(:role, can_view_assigned_reports: true, can_view_client_name: false) }

    it 'redacts first and last name when the user cannot view client names for the project' do
      destination_id = create_crosswalk(
        project: viewable_project,
        personal_id: 'PID-VIEWABLE',
        first_name: 'Ada',
        last_name: 'Lovelace',
      ).fetch(:destination_id)

      get_report(project_ids: [viewable_project.id])

      expect(response).to have_http_status(:success)
      row = assigns(:report).rows.find { |r| r[2] == destination_id }
      expect(row[3]).to eq(GrdaWarehouse::PiiProvider::REDACTED)
      expect(row[4]).to eq(GrdaWarehouse::PiiProvider::REDACTED)
    end

    it 'shows the name when at least one of the client\'s projects allows it, with map_enrollments off' do
      second_viewable_project = create(
        :hud_project,
        data_source_id: source_ds.id,
        OrganizationID: organization.OrganizationID,
        confidential: false,
      )
      collection.set_viewables(
        reports: [report_definition.id],
        projects: [viewable_project.id, confidential_project.id, second_viewable_project.id],
      )
      permissive_role = create(:role, can_view_assigned_reports: true, can_view_client_name: true)
      permissive_collection = create(:collection)
      permissive_collection.set_viewables(projects: [second_viewable_project.id])
      setup_access_control(user, permissive_role, permissive_collection)

      destination_id = create_crosswalk(
        project: viewable_project,
        personal_id: 'PID-MULTI',
        first_name: 'Ada',
        last_name: 'Lovelace',
      ).fetch(:destination_id)
      create(
        :grda_warehouse_hud_enrollment,
        data_source_id: source_ds.id,
        PersonalID: 'PID-MULTI',
        ProjectID: second_viewable_project.ProjectID,
        EntryDate: start_date + 1.day,
      )

      get_report(project_ids: [viewable_project.id, second_viewable_project.id])

      expect(response).to have_http_status(:success)
      row = assigns(:report).rows.find { |r| r[2] == destination_id }
      expect(row[3]).to eq('Ada')
      expect(row[4]).to eq('Lovelace')
    end

    context 'when the org has disabled PII in detail downloads' do
      # can_view_client_name alone is not sufficient for a "download"-mode PII policy
      # (see User#reporting_policy_for_project): the org-wide include_pii_in_detail_downloads
      # config must also be enabled, or every project's policy denies the name regardless of role.
      let(:role) { create(:role, can_view_assigned_reports: true, can_view_client_name: true) }

      before { GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: false) }

      it 'redacts the name even though the role otherwise allows viewing it' do
        destination_id = create_crosswalk(
          project: viewable_project,
          personal_id: 'PID-VIEWABLE',
          first_name: 'Ada',
          last_name: 'Lovelace',
        ).fetch(:destination_id)

        get_report(project_ids: [viewable_project.id])

        expect(response).to have_http_status(:success)
        row = assigns(:report).rows.find { |r| r[2] == destination_id }
        expect(row[3]).to eq(GrdaWarehouse::PiiProvider::REDACTED)
        expect(row[4]).to eq(GrdaWarehouse::PiiProvider::REDACTED)
      end
    end

    it 'redacts each row independently by its own enrollment\'s project when "Map enrollments" is requested' do
      # Unlike the map_enrollments-off case above (which aggregates "can view via any
      # project"), each mapped row is redacted using that specific enrollment's project
      # policy, so the same client can have one visible and one redacted row.
      second_viewable_project = create(
        :hud_project,
        data_source_id: source_ds.id,
        OrganizationID: organization.OrganizationID,
        confidential: false,
      )
      collection.set_viewables(
        reports: [report_definition.id],
        projects: [viewable_project.id, confidential_project.id, second_viewable_project.id],
      )
      permissive_role = create(:role, can_view_assigned_reports: true, can_view_client_name: true)
      permissive_collection = create(:collection)
      permissive_collection.set_viewables(projects: [second_viewable_project.id])
      setup_access_control(user, permissive_role, permissive_collection)

      crosswalk = create_crosswalk(
        project: viewable_project,
        personal_id: 'PID-MIXED',
        first_name: 'Ada',
        last_name: 'Lovelace',
      )
      second_enrollment = create(
        :grda_warehouse_hud_enrollment,
        data_source_id: source_ds.id,
        PersonalID: 'PID-MIXED',
        ProjectID: second_viewable_project.ProjectID,
        EntryDate: start_date + 1.day,
      )

      get_report(project_ids: [viewable_project.id, second_viewable_project.id], map_enrollments: true)

      expect(response).to have_http_status(:success)
      rows = assigns(:report).rows
      denied_row = rows.find { |r| r[5] == crosswalk.fetch(:enrollment).EnrollmentID }
      allowed_row = rows.find { |r| r[5] == second_enrollment.EnrollmentID }
      expect(denied_row[3]).to eq(GrdaWarehouse::PiiProvider::REDACTED)
      expect(denied_row[4]).to eq(GrdaWarehouse::PiiProvider::REDACTED)
      expect(allowed_row[3]).to eq('Ada')
      expect(allowed_row[4]).to eq('Lovelace')
    end
  end
end
