###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::WarehouseReports::TouchPoint, type: :model do
  describe '#clean_data' do
    # Legacy (non-ACL) user + role/access-group grant — matches the proven working pattern in
    # `drivers/homeless_summary_report/spec/requests/homeless_summary_report/warehouse_reports/reports_controller_details_spec.rb`,
    # itself resolving PII through `User#reporting_policy_for_client`/`SourceClientPolicy` the
    # same way this report now does. `can_view_client_name` alone is not sufficient —
    # `SourceClientPolicy#can_view_name?` requires the client be enrolled in a project the
    # access group has been granted (`access_group.add_viewable(project)` below), which is why
    # `unrestricted_source_client` gets a real `Hud::Enrollment` into `project`.
    let!(:role) { create(:role, can_view_clients: true, can_view_client_name: true) }
    let!(:access_group) { create(:access_group) }
    let!(:running_user) do
      user = create(:user)
      role.add(user)
      access_group.add(user)
      user
    end
    let!(:hmis_ds) { create(:hmis_primary_data_source) }
    let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
    let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Restricted', last_name: 'Client') }
    let!(:restricted_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Restricted', LastName: 'Client') }
    let!(:unrestricted_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Open', LastName: 'Client') }
    # The project/enrollment must live in the SAME data source as `unrestricted_source_client`
    # (`hmis_ds`) — `GrdaWarehouse::Hud::Project.joins(:clients)` (which the ACL/legacy permission
    # chain's `enrolled_project_ids_for_client` relies on) only resolves an enrollment's client
    # within that enrollment's own data source. `unrestricted_source_client` can't move to a
    # different data source either — `open_form` below needs it in `hmis_ds` for the touchpoint's
    # own `HmisForm`/`Hmis::Assessment` query logic to find it.
    let!(:organization) { create(:hud_organization, data_source: hmis_ds) }
    let!(:project) { create(:grda_warehouse_hud_project, organization: organization, data_source: hmis_ds) }
    # `Hud::Enrollment#client` strictly requires a `GrdaWarehouse::Hud::Client` instance —
    # `Hmis::Hud::Client` shares the same DB table but is a distinct AR class, so a plain
    # `unrestricted_source_client` (an `Hmis::Hud::Client`) raises `AssociationTypeMismatch`.
    let!(:unrestricted_enrollment) { create(:hud_enrollment, client: GrdaWarehouse::Hud::Client.find(unrestricted_source_client.id), project: project, data_source: hmis_ds) }

    let!(:report) do
      create(:touch_point_report_instance,
             user: running_user,
             parameters: { 'start' => 1.year.ago.to_date, 'end' => Date.tomorrow, 'name' => 'Intake' })
    end

    # No FactoryBot factory exists for GrdaWarehouse::HmisForm or GrdaWarehouse::Hmis::Assessment
    # anywhere in this codebase (confirmed via repo-wide grep) — build both directly. `touch_point_source`
    # (`GrdaWarehouse::HmisForm.non_confidential`) requires a joined `Hmis::Assessment` row with
    # `confidential: false`; `responses` additionally requires `hmis_assessment` to join and
    # `client: :destination_client` to resolve, and filters by `name: touch_point_name` and
    # `collected_at` inside the report's `start`/`end` window.
    let!(:hmis_assessment_row) do
      GrdaWarehouse::Hmis::Assessment.create!(
        data_source_id: hmis_ds.id,
        site_id: 1,
        assessment_id: 1,
        name: 'Intake',
        site_name: 'Main Site',
        confidential: false,
        active: true,
      )
    end
    let!(:restricted_form) do
      GrdaWarehouse::HmisForm.create!(
        client_id: restricted_source_client.id,
        data_source_id: hmis_ds.id,
        site_id: 1,
        assessment_id: 1,
        name: 'Intake',
        collected_at: Date.current,
        staff: 'Staff Member',
        answers: { sections: [] },
      )
    end
    let!(:open_form) do
      GrdaWarehouse::HmisForm.create!(
        client_id: unrestricted_source_client.id,
        data_source_id: hmis_ds.id,
        site_id: 1,
        assessment_id: 1,
        name: 'Intake',
        collected_at: Date.current,
        staff: 'Staff Member',
        answers: { sections: [] },
      )
    end
    let!(:unrestricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Open', last_name: 'Client') }

    # `GrdaWarehouse::Config.get` caches the settings row at the class level for 30 seconds,
    # independent of each example's DB transaction rollback — without this, an earlier example's
    # `include_pii_in_detail_downloads` change can leak into a later one regardless of run order.
    after { GrdaWarehouse::Config.invalidate_cache }

    before do
      access_group.add_viewable(project)
      GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_destination_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s)
      GrdaWarehouse::WarehouseClient.create!(destination_id: unrestricted_destination_client.id, source_id: unrestricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: unrestricted_source_client.id.to_s)
      restricted_source_client.mark_as_restricted!(user: hmis_user)
    end

    it 'redacts the client name for a restricted client and leaves the unrestricted client intact' do
      rows = report.clean_data(report.computed_data)[:data]
      restricted_row = rows.find { |row| row[0] == restricted_destination_client.id }
      open_row = rows.find { |row| row[0] == unrestricted_destination_client.id }

      expect(restricted_row[1]).to eq('Name Redacted')
      expect(open_row[1]).to eq('Open Client')
    end

    it 'redacts the unrestricted client name when the PII-download toggle is off, even though the user has real PII-view permission' do
      GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: false)
      GrdaWarehouse::Config.invalidate_cache

      rows = report.clean_data(report.computed_data)[:data]
      open_row = rows.find { |row| row[0] == unrestricted_destination_client.id }

      expect(open_row[1]).to eq('Name Redacted')
    end
  end
end
