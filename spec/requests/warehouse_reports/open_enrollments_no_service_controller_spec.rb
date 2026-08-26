###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'WarehouseReports::OpenEnrollmentsNoServiceController', type: :request do
  let!(:user) { create(:acl_user) }
  let!(:collection) { create(:collection) }
  # See Task 8's note on `:admin_role` granting no permissions by itself; this controller's project
  # join additionally needs `can_view_projects` for `Project.viewable_by` to resolve. It also needs
  # `can_view_assigned_reports` (not just `can_view_all_reports`) — for an ACL user,
  # `ReportDefinition.viewable_by` (the `before_action :report_visible?` check) requires
  # `can_view_assigned_reports?` specifically, same root cause as Task 8's role-factory fix.
  # `can_view_client_name` grants nothing by itself without the project-based ACL grant below
  # (`collection.set_viewables({..., projects: [project.id]})`) — added so the fixture can
  # distinguish "blocked by the download toggle" from "blocked by lacking PII permission at all"
  # (see the toggle test below). `ProjectPiiPolicy` (unlike the client-based policy) resolves
  # permission purely via `project_role_permissions`, with no client/data-source alignment
  # required, so this is simpler to grant than the client-based policies elsewhere in this build.
  let!(:role) { create(:role, can_view_all_reports: true, can_view_assigned_reports: true, can_view_projects: true, can_view_client_name: true) }
  let!(:report) { create(:touch_point_report, url: 'warehouse_reports/open_enrollments_no_service', name: 'Open Enrollments') }

  let!(:hmis_ds) { create(:hmis_primary_data_source) }
  let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
  let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Restricted', last_name: 'Client') }
  let!(:restricted_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Restricted', LastName: 'Client') }
  let!(:open_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Open', last_name: 'Client') }
  let!(:open_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Open', LastName: 'Client') }
  # `Project.viewable_by` (via `.es.viewable_by(current_user)` in the controller) chains
  # `.non_confidential`, which inner-joins `:organization` — an org with a matching
  # `data_source_id`/`OrganizationID` is required or the join silently drops the project.
  let!(:project_data_source) { create(:grda_warehouse_data_source) }
  let!(:organization) { create(:hud_organization, data_source: project_data_source) }
  let!(:project) { create(:hud_project, data_source: project_data_source, OrganizationID: organization.OrganizationID, ProjectType: 1, TrackingMethod: 3) } # ES, Night-by-Night
  # `she_entry` (the real factory; there is no generic `:service_history_enrollment` factory in
  # this codebase) is used elsewhere with an `enrollment:` association to auto-populate
  # project/household linkage — see `drivers/hud_spm_report/spec/models/fy2026/spm_enrollment_builder_spec.rb`.
  # `open_enrollments_no_service_controller#index` filters via `.entry.ongoing.es_nbn` (all real
  # scopes on `GrdaWarehouse::ServiceHistoryEnrollment` — `ongoing` = `first_date_in_program <= on_date
  # AND (last_date_in_program IS NULL OR last_date_in_program > on_date)`; `es_nbn` requires an ES
  # project with `TrackingMethod` set to Night-by-Night, matching the `TrackingMethod: 3` above).
  # `es_nbn` (`app/models/grda_warehouse/service_history_enrollment.rb`) filters on the SHE's own
  # `project_type` column (`where project_type: [1]`, per `HudHelper.util.performance_reporting[:es_nbn]`
  # — `1` is HUD's "Emergency Shelter - Night-by-Night" project type code). That column is a
  # denormalized copy on `service_history_enrollments`, not derived from the `project:` association by
  # the `:she_entry` factory or any model callback, so it must be set explicitly here to match.
  let!(:she) do
    create(:she_entry, client: restricted_destination_client, project: project,
                       record_type: :entry, project_type: 1, first_date_in_program: 2.years.ago.to_date, last_date_in_program: nil)
  end
  let!(:open_she) do
    create(:she_entry, client: open_destination_client, project: project,
                       record_type: :entry, project_type: 1, first_date_in_program: 2.years.ago.to_date, last_date_in_program: nil)
  end

  # `GrdaWarehouse::Config.get` caches the settings row at the class level for 30 seconds,
  # independent of each example's DB transaction rollback — without this, an earlier example's
  # `include_pii_in_detail_downloads` change can leak into a later one regardless of run order.
  after { GrdaWarehouse::Config.invalidate_cache }

  before do
    Collection.maintain_system_groups
    # `service_history_enrollment_source` (in the controller) additionally merges
    # `GrdaWarehouse::Hud::Project.es.viewable_by(current_user)` — a separate ACL check from report
    # visibility — so `project` must also be granted through the same collection, and the role needs
    # general project-view permission.
    collection.set_viewables({ reports: [report.id], projects: [project.id] })
    setup_access_control(user, role, collection)
    GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_destination_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s)
    GrdaWarehouse::WarehouseClient.create!(destination_id: open_destination_client.id, source_id: open_source_client.id, data_source_id: hmis_ds.id, id_in_source: open_source_client.id.to_s)
    restricted_source_client.mark_as_restricted!(user: hmis_user)
    sign_in user
  end

  it 'redacts the client name for a restricted client' do
    get warehouse_reports_open_enrollments_no_service_index_path

    expect(response.body).not_to include('Restricted Client')
    expect(response.body).to include('Name Redacted')
  end

  # `.xlsx` responses are a compressed OOXML zip, not plain text — `response.body.include?` would
  # pass even on unredacted data, since the raw string never appears uncompressed. Parse the actual
  # workbook instead, matching the pattern in Task 8's `chronic_housed_controller_spec.rb` (itself
  # matching `spec/requests/cohorts/reports_controller_spec.rb`).
  def rendered_workbook
    excel_file = Tempfile.new(['open_enrollments_no_service', '.xlsx'])
    excel_file.binmode
    excel_file.write(response.body)
    excel_file.close
    Roo::Excelx.new(excel_file.path)
  ensure
    excel_file&.unlink
  end

  it 'redacts the client name in the Excel export' do
    get warehouse_reports_open_enrollments_no_service_index_path(format: :xlsx)

    expect(response).to have_http_status(:success)
    data_row = rendered_workbook.sheet(0).row(2)
    expect(data_row[1]).to eq('Name Redacted')
    expect(data_row[2]).to eq('Name Redacted')
  end

  # Proves the Excel export is gated by the org-wide `include_pii_in_detail_downloads` download
  # toggle, independent of restriction — the same `mode: :download` distinction every other bulk
  # PII export in this codebase honors. Uses the unrestricted client so restriction can't explain
  # the redaction either way; the first assertion proves this user has real PII-view permission
  # (name shows in the browse-mode HTML view regardless of the toggle), so the Excel-only
  # redaction below is attributable to the toggle, not a missing permission.
  it 'shows the unrestricted client name in the HTML view but redacts it in the Excel export when the download toggle is off' do
    GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: false)
    GrdaWarehouse::Config.invalidate_cache

    get warehouse_reports_open_enrollments_no_service_index_path
    expect(response.body).to include('Open Client')

    get warehouse_reports_open_enrollments_no_service_index_path(format: :xlsx)
    expect(response).to have_http_status(:success)
    sheet = rendered_workbook.sheet(0)
    row = (sheet.first_row..sheet.last_row).map { |i| sheet.row(i) }.find { |r| r[0] == open_destination_client.id }
    expect(row[1]).to eq('Name Redacted')
    expect(row[2]).to eq('Name Redacted')
  end
end
