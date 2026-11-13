###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'nokogiri'

# The count table is rendered by BackgroundRender::AnalysisToolJob, outside any request, so the
# drill-down links it emits are built here rather than through the controller's index action.
RSpec.describe 'AnalysisTool::WarehouseReports::AnalysisTool drill-down links', type: :request do
  let!(:user) { create(:acl_user) }
  let!(:role) { create(:role, can_view_assigned_reports: true, can_view_clients: true, can_view_projects: true, can_view_project_related_filters: true) }
  let!(:collection) { create(:collection) }
  let!(:report_definition) { create(:touch_point_report, url: AnalysisTool::Report.url, name: 'Analysis Tool') }

  let!(:data_source) { create(:visible_data_source) }
  let!(:organization) { create(:hud_organization, data_source: data_source) }
  let!(:selected_project) { create(:hud_project, data_source: data_source, OrganizationID: organization.OrganizationID, ProjectType: 1) }
  let!(:other_project) { create(:hud_project, data_source: data_source, OrganizationID: organization.OrganizationID, ProjectType: 1) }

  let!(:selected_client) { create(:grda_warehouse_hud_client, DOB: Date.new(1980, 1, 1), Woman: 1) }
  let!(:other_client) { create(:grda_warehouse_hud_client, DOB: Date.new(1980, 1, 1), Woman: 1) }

  let(:start_date) { Date.new(2026, 1, 1) }
  let(:end_date) { Date.new(2026, 12, 31) }

  before do
    Rails.cache.clear
    Collection.maintain_system_groups
    collection.set_viewables({ reports: [report_definition.id], projects: [selected_project.id, other_project.id] })
    setup_access_control(user, role, collection)

    [[selected_client, selected_project], [other_client, other_project]].each do |client, project|
      create(:grda_warehouse_warehouse_clients_processed, client: client)
      create(:she_entry, client: client, project: project, project_type: 1, computed_project_type: 1, first_date_in_program: start_date + 1.month, last_date_in_program: nil, date: start_date + 1.month)
    end

    sign_in(user)
  end

  def filter
    ::Filters::FilterBase.new(user_id: user.id).set_from_params(
      start: start_date, end: end_date, project_ids: [selected_project.id], require_service_during_range: false,
    )
  end

  def rendered_table
    html = BackgroundRender::AnalysisToolJob.new.render_html(
      filters: filter.for_params[:filters].to_json,
      user_id: user.id,
      row_breakdown: :age,
      col_breakdown: :gender,
    )
    Nokogiri::HTML5.fragment(html)
  end

  def drill_down_links(doc)
    doc.css('a[href*="/details"]')
  end

  it 'includes the report filter in every drill-down link' do
    links = drill_down_links(rendered_table)

    expect(links).not_to be_empty
    links.each do |link|
      query = Rack::Utils.parse_nested_query(URI.parse(link['href']).query)
      expect(query.dig('filters', 'project_ids')).to eq([selected_project.id.to_s])
      expect(query.dig('filters', 'start')).to eq(start_date.to_s)
      expect(query.dig('filters', 'end')).to eq(end_date.to_s)
    end
  end

  it 'lists only the clients counted in the cell when the drill-down link is followed' do
    link = drill_down_links(rendered_table).first

    get link['href']

    expect(response).to have_http_status(:success)
    expect(response.body).to include('Showing 1 client')
    expect(response.body).to include(">#{selected_client.id}<")
    expect(response.body).not_to include(">#{other_client.id}<")
  end
end
