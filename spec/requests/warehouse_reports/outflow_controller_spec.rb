###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'WarehouseReports::OutflowController', type: :request do
  let!(:user) { create(:acl_user) }
  let!(:collection) { create(:collection) }
  let!(:role) { create(:role, can_view_all_reports: true, can_view_assigned_reports: true, can_view_projects: true) }
  let!(:report) { create(:touch_point_report, url: 'warehouse_reports/outflow', name: 'Client Outflow') }

  let!(:data_source) { create(:grda_warehouse_data_source) }
  let!(:organization) { create(:hud_organization, data_source: data_source) }
  let!(:project) { create(:hud_project, data_source: data_source, OrganizationID: organization.OrganizationID, ProjectType: 1) } # ES
  let!(:destination_client) { create(:grda_warehouse_hud_client) }
  let!(:exit_enrollment) do
    create(
      :she_entry,
      client: destination_client,
      project: project,
      project_type: 1,
      first_date_in_program: 6.months.ago.to_date,
      last_date_in_program: 1.month.ago.to_date,
      destination: HudHelper.util.permanent_destinations.first,
    )
  end

  let(:filter_params) { { start: 1.year.ago.to_date, end: Date.current } }

  before do
    Collection.maintain_system_groups
    collection.set_viewables({ reports: [report.id], projects: [project.id] })
    setup_access_control(user, role, collection)
    sign_in user
  end

  def clients_to_ph_count
    Nokogiri::HTML(response.body).
      at_xpath("//tr[td/a[normalize-space()='Clients exiting to Permanent Destinations']]/td[2]").
      text.strip
  end

  it 'shows the in-scope exit for the default sub-population' do
    get warehouse_reports_outflow_index_path, params: { filter: filter_params }

    expect(response).to have_http_status(:ok)
    expect(clients_to_ph_count).to eq('1')
  end

  it 'raises for an unregistered sub-population' do
    expect { get warehouse_reports_outflow_index_path, params: { filter: filter_params.merge(sub_population: 'children') } }.
      to raise_error(AvailableSubPopulations::UnknownSubPopulation)
  end
end
