###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Health Emergency clinical tables', type: :request do
  let!(:user) { create(:acl_user) }
  # `UploadedResultsController` also `include WarehouseReportAuthorization` (`before_action
  # :require_can_view_any_reports!`), on top of the health-emergency-specific gate — see Task 8's
  # note on why this can't be left implicit. It also needs `can_view_assigned_reports` (not just
  # `can_view_all_reports`) for `report_visible?` -- for an ACL user, `ReportDefinition.viewable_by`
  # requires `can_view_assigned_reports?` specifically -- and `can_see_health_emergency` (a
  # separate permission from `can_see_health_emergency_clinical`), since
  # `WarehouseReportsHealthEmergencyController`'s `require_health_emergency!` gates on
  # `ApplicationController#health_emergency?`, which checks `current_user.can_see_health_emergency?`
  # alongside a truthy `GrdaWarehouse::Config#health_emergency` (set in the `before` block below).
  let!(:role) do
    create(:role, can_see_health_emergency: true, can_see_health_emergency_clinical: true, can_edit_health_emergency_clinical: true,
                  can_view_all_reports: true, can_view_assigned_reports: true)
  end
  let!(:collection) { create(:collection) }
  let!(:report) { create(:touch_point_report, url: 'warehouse_reports/health_emergency/uploaded_results', name: 'Upload Test Results') }

  let!(:hmis_ds) { create(:hmis_primary_data_source) }
  let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
  let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Restricted', last_name: 'Client') }
  let!(:restricted_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Restricted', LastName: 'Client') }

  # No FactoryBot factory exists for GrdaWarehouse::HealthEmergency::TestBatch or ::UploadedTest
  # anywhere in this codebase (confirmed via repo-wide grep of spec/factories) — build directly.
  # `TestBatch belongs_to :user, optional: true`; `UploadedTest belongs_to :batch, ... optional: true`
  # (default foreign key `batch_id`) and `belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', optional: true`.
  # `TestBatch` inherits a required `belongs_to :client` from the `HealthEmergency` concern, but
  # `health_emergency_test_batches` has no `client_id` column at all -- `create!` always fails that
  # presence check, matching the controller's own "so this create is inert" comment
  # (`uploaded_results_controller.rb`). Save without validation to build a batch here.
  let!(:batch) do
    GrdaWarehouse::HealthEmergency::TestBatch.new(user: user).tap { |b| b.save!(validate: false) }
  end
  let!(:uploaded_test) do
    GrdaWarehouse::HealthEmergency::UploadedTest.create!(batch: batch, client: restricted_destination_client, first_name: 'Restricted', last_name: 'Client', dob: Date.new(1990, 1, 1), ssn: '111223333', tested_on: Date.current, test_result: 'Negative', test_location: 'Clinic A')
  end
  # Unmatched row — no `client:` set. Proves the fail-closed default: an upload that has never
  # been reconciled to a real client record shows redacted PII, not raw PII, even though there's
  # no restriction to check (there's no destination client id to check it against).
  #
  # `UploadedTest`'s own `belongs_to :client, optional: true` doesn't clear the required-presence
  # validator added by the `HealthEmergency` concern's earlier `belongs_to :client` (redeclaring a
  # `belongs_to` under the same name doesn't remove validators the first declaration added) --
  # `create!` with no `client:` always raises `Client must exist`. `TestBatch#match_clients!`
  # (`test_batch.rb`) hits this too, via a plain `client.save` that silently returns false for an
  # unmatched row -- a pre-existing, unrelated persistence bug, out of scope for this PII task.
  # Bypass validation here to build a genuinely-unmatched row for the view-layer assertions below.
  let!(:unmatched_uploaded_test) do
    GrdaWarehouse::HealthEmergency::UploadedTest.new(batch: batch, first_name: 'Unmatched', last_name: 'Person', dob: Date.new(1985, 5, 5), ssn: '444556666', tested_on: Date.current, test_result: 'Negative', test_location: 'Clinic B').
      tap { |t| t.save!(validate: false) }
  end

  before do
    Collection.maintain_system_groups
    collection.set_viewables({ reports: [report.id] })
    setup_access_control(user, role, collection)
    GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_destination_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s)
    restricted_source_client.mark_as_restricted!(user: hmis_user)
    # `require_health_emergency!` (`WarehouseReportsHealthEmergencyController`) additionally
    # requires a truthy `GrdaWarehouse::Config#health_emergency`.
    GrdaWarehouse::Config.first_or_create.update!(health_emergency: 'boston_covid_19')
    sign_in user
  end

  # The uploaded-test rows (with their own raw first_name/last_name/dob) are rendered by
  # `_tests_table`, which the `show` action renders for a single batch -- `index` lists batches,
  # not individual results, and its `@results` (`TestBatch` records) have no `client_id` at all.
  # See the task report's "deviation" note for the full explanation.
  it 'redacts the uploaded test row name for a restricted client' do
    get warehouse_reports_health_emergency_uploaded_result_path(batch)

    expect(response.body).not_to include('Restricted Client')
    expect(response.body).to include('Name Redacted')
  end

  # `PiiProvider#ssn` masks to the last four digits (`XXX-XX-####`) rather than a bare "Redacted"
  # string when the viewer can't see the full number — matching `#dob`/`#full_name`'s policy, but
  # the *full* raw SSN must never appear either way.
  it 'masks the SSN for a restricted client and never renders the full raw number' do
    get warehouse_reports_health_emergency_uploaded_result_path(batch)

    expect(response.body).not_to include('111223333')
    expect(response.body).not_to include('111-22-3333')
  end

  it 'redacts the uploaded test row name for an unmatched (unreconciled) row' do
    get warehouse_reports_health_emergency_uploaded_result_path(batch)

    expect(response.body).not_to include('Unmatched')
    expect(response.body).not_to include('Person')
    expect(response.body).not_to include('1985-05-05')
    # Both the matched-restricted row and this unmatched row redact first/last name, so
    # "Name Redacted" appears at least twice -- proves this row's names were genuinely
    # replaced, not just coincidentally blank.
    expect(response.body.scan('Name Redacted').size).to be >= 2
  end
end
