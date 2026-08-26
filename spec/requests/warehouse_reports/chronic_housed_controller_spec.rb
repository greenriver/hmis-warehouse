###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'WarehouseReports::ChronicHousedController', type: :request do
  let!(:user) { create(:acl_user) }
  let!(:collection) { create(:collection) }
  # `WarehouseReportAuthorization#report_visible?` calls `ReportDefinition.viewable_by(current_user)`,
  # which for an ACL user (`:acl_user` below) requires `can_view_assigned_reports?` specifically —
  # it looks up collections granted that permission and joins on `GroupViewableEntity` for the
  # report (satisfied by `collection.set_viewables` below). `can_view_all_reports` alone (as
  # granted by a bare `create(:role, can_view_all_reports: true)`) only satisfies the separate
  # `before_action :require_can_view_any_reports!` check, not `report_visible?`, and the request
  # 302s to `/warehouse_reports` before reaching the controller action. `:report_viewer`
  # (`spec/factories/roles.rb`) grants both permissions, matching the pattern already used in
  # `spec/requests/warehouse_reports/touch_point_exports_controller_spec.rb`.
  # `can_view_client_name` grants nothing by itself without a project-based ACL grant — added so
  # the fixture can distinguish "blocked by the download toggle" from "blocked by lacking PII
  # permission at all" (see the toggle test below).
  let!(:role) { create(:report_viewer, can_view_client_name: true) }
  let!(:report) { create(:touch_point_report, url: 'warehouse_reports/chronic_housed', name: 'Chronic Housed') }

  let!(:hmis_ds) { create(:hmis_primary_data_source) }
  let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
  let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Restricted', last_name: 'Client') }
  let!(:restricted_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Restricted', LastName: 'Client') }
  let!(:open_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Open', last_name: 'Client') }
  let!(:open_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Open', LastName: 'Client') }
  # `project` must share a data source with any client the ACL project-grant needs to cover —
  # `GrdaWarehouse::Hud::Project.joins(:clients)` (which the permission chain's
  # `enrolled_project_ids_for_client` relies on) only resolves an enrollment's client within that
  # enrollment's own data source, so `project` lives in `hmis_ds` rather than its factory default.
  let!(:project) { create(:hud_project, data_source: hmis_ds) }
  # `Hud::Enrollment#client` strictly requires a `GrdaWarehouse::Hud::Client` instance —
  # `Hmis::Hud::Client` shares the same DB table but is a distinct AR class.
  let!(:open_enrollment) { create(:hud_enrollment, client: GrdaWarehouse::Hud::Client.find(open_source_client.id), project: project, data_source: hmis_ds) }
  # `:she_entry` is the real factory (there is no generic `:service_history_enrollment` factory
  # anywhere in this codebase).
  let!(:she) do
    # destination 10 (legacy "rental by client, no ongoing housing subsidy") isn't a permanent
    # destination under the 2026 HUD spec (`HudHelper.util` pins '2026' outside prod/staging,
    # see `lib/util/hud_helper.rb`) — `HudUtility2026.permanent_destinations` only covers codes
    # 400-499. 410 is the 2026-numbered equivalent, and does fall in that range.
    create(:she_entry, client: restricted_destination_client, project: project,
                       record_type: :entry, destination: 410, last_date_in_program: 2.months.ago.to_date)
  end
  let!(:open_she) do
    create(:she_entry, client: open_destination_client, project: project,
                       record_type: :entry, destination: 410, last_date_in_program: 2.months.ago.to_date)
  end
  let!(:chronic) { create(:chronic, client_id: restricted_destination_client.id, date: 2.months.ago.to_date) }
  let!(:open_chronic) { create(:chronic, client_id: open_destination_client.id, date: 2.months.ago.to_date) }

  # `GrdaWarehouse::Config.get` caches the settings row at the class level for 30 seconds,
  # independent of each example's DB transaction rollback — without this, an earlier example's
  # `include_pii_in_detail_downloads` change can leak into a later one regardless of run order.
  after { GrdaWarehouse::Config.invalidate_cache }

  before do
    Collection.maintain_system_groups
    collection.set_viewables({ reports: [report.id], projects: [project.id] })
    setup_access_control(user, role, collection)
    GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_destination_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s)
    GrdaWarehouse::WarehouseClient.create!(destination_id: open_destination_client.id, source_id: open_source_client.id, data_source_id: hmis_ds.id, id_in_source: open_source_client.id.to_s)
    restricted_source_client.mark_as_restricted!(user: hmis_user)
    sign_in user
  end

  it 'redacts the client name for a restricted client' do
    get warehouse_reports_chronic_housed_index_path

    expect(response.body).not_to include('Restricted Client')
    expect(response.body).to include('Name Redacted')
  end

  # `.xlsx` responses are a compressed OOXML zip, not plain text — `response.body.include?` would
  # pass even on unredacted data, since the raw string never appears uncompressed. Parse the actual
  # workbook instead, matching the established pattern in
  # `spec/requests/cohorts/reports_controller_spec.rb`.
  def rendered_workbook
    excel_file = Tempfile.new(['chronic_housed', '.xlsx'])
    excel_file.binmode
    excel_file.write(response.body)
    excel_file.close
    Roo::Excelx.new(excel_file.path)
  ensure
    excel_file&.unlink
  end

  it 'redacts the client name in the Excel export regardless of the PII-download setting' do
    GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: true)

    get warehouse_reports_chronic_housed_index_path(format: :xlsx)

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
    # `GrdaWarehouse::Config.get` caches the settings row at the class level for 30 seconds,
    # independent of the per-example DB transaction rollback — explicit invalidation matches the
    # established pattern elsewhere in this codebase (e.g. `spec/models/grda_warehouse/client_file_spec.rb`)
    # and avoids this example's toggle value leaking into whichever example runs next.
    GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: false)
    GrdaWarehouse::Config.invalidate_cache

    get warehouse_reports_chronic_housed_index_path
    expect(response.body).to include('Open Client')

    get warehouse_reports_chronic_housed_index_path(format: :xlsx)
    expect(response).to have_http_status(:success)
    sheet = rendered_workbook.sheet(0)
    row = (sheet.first_row..sheet.last_row).map { |i| sheet.row(i) }.find { |r| r[0] == open_destination_client.id }
    expect(row[1]).to eq('Name Redacted')
    expect(row[2]).to eq('Name Redacted')
  end
end
