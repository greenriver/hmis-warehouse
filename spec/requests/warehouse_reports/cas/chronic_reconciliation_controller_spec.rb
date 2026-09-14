###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../shared_contexts/hud_enrollment_builders'

RSpec.describe 'WarehouseReports::Cas::ChronicReconciliationController#index', type: :request do
  include_context 'HUD enrollment builders'

  let!(:user) { create(:acl_user) }
  let!(:collection) { create(:collection) }
  let!(:role) { create(:role, can_view_all_reports: true, can_view_assigned_reports: true, can_view_client_name: true, can_view_clients: true, can_view_projects: true) }
  let!(:report) { create(:touch_point_report, url: 'warehouse_reports/cas/chronic_reconciliation', name: 'Chronic Reconciliation') }

  let!(:hmis_user) { create(:hmis_user, data_source: destination_data_source) }
  let!(:project) { create_project(project_type: 1) }

  # Left half of the report ("... Not Flagged for CAS"): chronic on the filter date with a homeless
  # service in range, and not flagged for CAS.
  let!(:restricted_chronic_source) { create_client_with_warehouse_link(first_name: 'Restrictedfirst', last_name: 'Restrictedlast') }
  let!(:open_chronic_source) { create_client_with_warehouse_link(first_name: 'Openfirst', last_name: 'Openlast') }

  # Right half ("Flagged for CAS, Not in Chronic List"): AR clients with sync_with_cas and no chronic row.
  let!(:restricted_cas_source) { create_client_with_warehouse_link(first_name: 'Restrictedcasfirst', last_name: 'Restrictedcaslast') }
  let!(:open_cas_source) { create_client_with_warehouse_link(first_name: 'Opencasfirst', last_name: 'Opencaslast') }

  after { GrdaWarehouse::Config.invalidate_cache }

  before do
    Collection.maintain_system_groups
    collection.set_viewables({ reports: [report.id], projects: [project.id] })
    setup_access_control(user, role, collection)

    [restricted_chronic_source, open_chronic_source].each do |source|
      enrollment = create_enrollment(client: source, project: project, entry_date: Date.current)
      create_bed_night_service(enrollment: enrollment, date: Date.current)
    end
    # The CAS-flagged clients need an enrollment too -- `client.pii_provider(user:)` (used by the
    # "not in chronic list" half) grants name visibility only through the viewer's project-based
    # role permissions, not merely because the client isn't restricted.
    [restricted_cas_source, open_cas_source].each do |source|
      create_enrollment(client: source, project: project, entry_date: Date.current)
    end
    GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)

    [restricted_chronic_source, open_chronic_source].each do |source|
      create(:chronic, client_id: source.destination_client.id, date: Date.current, days_in_last_three_years: 400)
    end
    [restricted_cas_source, open_cas_source].each do |source|
      source.destination_client.update!(sync_with_cas: true)
    end

    Hmis::Hud::Client.find(restricted_chronic_source.id).mark_as_restricted!(user: hmis_user)
    Hmis::Hud::Client.find(restricted_cas_source.id).mark_as_restricted!(user: hmis_user)

    sign_in user
  end

  it 'lists the chronic-but-not-flagged clients, redacting only the restricted one' do
    get warehouse_reports_cas_chronic_reconciliation_index_path

    # The left heading renders "Not Flagged for CAS" then "(count)" on the next line.
    expect(response.body).to match(/Not Flagged for CAS\s*\(2\)/)
    expect(response.body).not_to include('Restrictedfirst')
    expect(response.body).not_to include('Restrictedlast')
    expect(response.body).to include('Openfirst Openlast')
    expect(response.body).to include('Name Redacted')
  end

  it 'lists the flagged-but-not-chronic clients, redacting only the restricted one' do
    get warehouse_reports_cas_chronic_reconciliation_index_path

    expect(response.body).not_to include('Restrictedcasfirst')
    expect(response.body).not_to include('Restrictedcaslast')
    expect(response.body).to include('Opencasfirst Opencaslast')
  end

  it 'renders the filter date in both section headings' do
    get warehouse_reports_cas_chronic_reconciliation_index_path

    expect(response.body.scan(Date.current.strftime(Date::DATE_FORMATS[:default])).size).to be >= 2
  end
end
