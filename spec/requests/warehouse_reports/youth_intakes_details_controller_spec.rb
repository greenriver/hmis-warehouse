###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'WarehouseReports::YouthIntakesController#details', type: :request do
  let!(:user) { create(:acl_user) }
  let!(:collection) { create(:collection) }
  let!(:role) { create(:role, can_view_all_reports: true, can_view_assigned_reports: true, can_view_client_name: true) }
  let!(:report) { create(:touch_point_report, url: 'warehouse_reports/youth_intakes', name: 'Homeless Youth Report') }

  let!(:hmis_ds) { create(:hmis_primary_data_source) }
  let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
  let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Restricted', last_name: 'Client') }
  let!(:restricted_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Restricted', LastName: 'Client') }

  before do
    Collection.maintain_system_groups
    collection.set_viewables({ reports: [report.id] })
    setup_access_control(user, role, collection)
    GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_destination_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s)
    restricted_source_client.mark_as_restricted!(user: hmis_user)

    GrdaWarehouse::YouthIntake::Entry.create!(
      client: restricted_destination_client,
      engagement_date: Date.current,
      turned_away: false,
      staff_name: 'Staff',
      staff_email: 'staff@example.com',
      unaccompanied: false,
      street_outreach_contact: false,
      housing_status: 'foo',
      other_agency_involvements: 'none',
      secondary_education: 'foo',
      attending_college: false,
      health_insurance: false,
      staff_believes_youth_under_24: false,
      client_gender: 'foo',
      client_lgbtq: false,
      client_primary_language: 'English',
      pregnant_or_parenting: false,
      needs_shelter: false,
      in_stable_housing: false,
      youth_experiencing_homelessness_at_start: false,
      client_race: 'foo',
      disabilities: 'none',
      requesting_financial_assistance: false,
    )

    sign_in user
  end

  it 'redacts the restricted client name' do
    get details_warehouse_reports_youth_intakes_path(key: 'total_client_ids_served', filter: { start: 1.month.ago.to_date, end: Date.current })

    expect(response.body).not_to include('Restricted')
    expect(response.body).to include('Name Redacted')
  end
end
