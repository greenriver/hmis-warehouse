###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'WarehouseReports::Cas::RrhDesiredController', type: :request do
  let!(:user) { create(:acl_user) }
  let!(:collection) { create(:collection) }
  let!(:role) { create(:role, can_view_all_reports: true, can_view_assigned_reports: true, can_view_client_name: true) }
  let!(:report) { create(:touch_point_report, url: 'warehouse_reports/cas/rrh_desired', name: 'Clients Interested in RRH with no Consent') }

  let!(:hmis_ds) { create(:hmis_primary_data_source) }
  let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
  let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Restricted', last_name: 'Client') }
  let!(:restricted_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Restricted', LastName: 'Client') }
  let!(:open_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Open', last_name: 'Client') }
  let!(:open_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Open', LastName: 'Client') }
  let!(:organization) { create(:hud_organization, data_source: hmis_ds) }
  let!(:project) { create(:hud_project, data_source: hmis_ds, OrganizationID: organization.OrganizationID) }
  # `SourceClientPolicy#add_project_based_permissions` grants the role's `can_view_client_name`
  # permission only for projects a *source* client has a real HUD enrollment in
  # (`Project#clients` joins `:enrollments`).
  let!(:enrollment) { create(:hud_enrollment, client: GrdaWarehouse::Hud::Client.find(restricted_source_client.id), project: project, data_source: hmis_ds) }
  let!(:open_enrollment) { create(:hud_enrollment, client: GrdaWarehouse::Hud::Client.find(open_source_client.id), project: project, data_source: hmis_ds) }
  let!(:pathways_assessment) do
    GrdaWarehouse::Hmis::Assessment.create!(assessment_id: 1, site_id: 1, name: 'Pathways', data_source_id: hmis_ds.id, pathways: true)
  end
  let!(:restricted_form) do
    GrdaWarehouse::HmisForm.create!(
      client_id: restricted_source_client.id,
      data_source_id: hmis_ds.id,
      assessment_id: pathways_assessment.assessment_id,
      site_id: pathways_assessment.site_id,
      collection_location: 'Site A',
      collected_at: 1.day.ago,
      staff: 'A Staffer',
      staff_email: 'staffer@example.com',
      rrh_desired: 'Yes',
    )
  end
  let!(:open_form) do
    GrdaWarehouse::HmisForm.create!(
      client_id: open_source_client.id,
      data_source_id: hmis_ds.id,
      assessment_id: pathways_assessment.assessment_id,
      site_id: pathways_assessment.site_id,
      collection_location: 'Site A',
      collected_at: 1.day.ago,
      staff: 'A Staffer',
      staff_email: 'staffer@example.com',
      rrh_desired: 'Yes',
    )
  end

  before do
    Collection.maintain_system_groups
    collection.set_viewables({ reports: [report.id], projects: [project.id] })
    setup_access_control(user, role, collection)
    GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_destination_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s)
    GrdaWarehouse::WarehouseClient.create!(destination_id: open_destination_client.id, source_id: open_source_client.id, data_source_id: hmis_ds.id, id_in_source: open_source_client.id.to_s)
    restricted_source_client.mark_as_restricted!(user: hmis_user)
    sign_in user
  end

  it 'redacts the combined name cell for a restricted client and shows the unrestricted client normally' do
    get warehouse_reports_cas_rrh_desired_index_path

    expect(response.body).not_to include('Restricted Client')
    expect(response.body).to include('Name Redacted')
    expect(response.body).to include('Open Client')
  end
end
