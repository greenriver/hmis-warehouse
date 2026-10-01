###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Health Emergency clinical tables', type: :request do
  let!(:user) { create(:acl_user) }
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

  let!(:batch) do
    GrdaWarehouse::HealthEmergency::TestBatch.new(user: user).tap { |b| b.save!(validate: false) }
  end
  let!(:uploaded_test) do
    GrdaWarehouse::HealthEmergency::UploadedTest.create!(batch: batch, client: restricted_destination_client, first_name: 'Restricted', last_name: 'Client', dob: Date.new(1990, 1, 1), ssn: '111223333', tested_on: Date.current, test_result: 'Negative', test_location: 'Clinic A')
  end

  let!(:unmatched_uploaded_test) do
    GrdaWarehouse::HealthEmergency::UploadedTest.create!(batch: batch, first_name: 'Unmatched', last_name: 'Person', dob: Date.new(1985, 5, 5), ssn: '444556666', tested_on: Date.current, test_result: 'Negative', test_location: 'Clinic B')
  end

  before do
    Collection.maintain_system_groups
    collection.set_viewables({ reports: [report.id] })
    setup_access_control(user, role, collection)
    GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_destination_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s)
    restricted_source_client.mark_as_restricted!(user: hmis_user)
    # `require_health_emergency!` (`WarehouseReportsHealthEmergencyController`) additionally
    # requires a truthy `GrdaWarehouse::Config#health_emergency`. `Config.get` caches the
    # settings row at the class level for 30 seconds, independent of each example's DB
    # transaction rollback — invalidate so this value can't leak to/from another spec file
    # running in the same process (matches the pattern in `chronic_housed_controller_spec.rb`).
    GrdaWarehouse::Config.first_or_create.update!(health_emergency: 'boston_covid_19')
    GrdaWarehouse::Config.invalidate_cache
    sign_in user
  end

  after { GrdaWarehouse::Config.invalidate_cache }

  it 'redacts the uploaded test row name for a restricted client' do
    get warehouse_reports_health_emergency_uploaded_result_path(batch)

    expect(response.body).not_to include('Restricted Client')
    expect(response.body).to include('Name Redacted')
  end

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
    expect(response.body.scan('Name Redacted').size).to be >= 2
  end
end
