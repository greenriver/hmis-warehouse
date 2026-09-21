###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'PublicReports::WarehouseReports::StateLevelHomelessness sections', type: :request do
  include AccessControlSetup

  let(:user) { create(:acl_user) }
  let(:role) { create(:role, can_view_assigned_reports: true) }
  let(:collection) { create(:collection) }
  let!(:report_definition) do
    GrdaWarehouse::WarehouseReports::ReportDefinition.create!(
      report_group: 'Reports',
      url: 'public_reports/warehouse_reports/state_level_homelessness',
      name: 'State-Level Homelessness Report',
      description: '',
    )
  end

  let(:precalculated_data) { File.read(Rails.root.join('spec/fixtures/files/public_reports/state_level_v2.json')) }

  let!(:report) do
    r = PublicReports::StateLevelHomelessness.new(
      user: user,
      filter: { filters: { start: Date.parse('2024-01-01'), end: Date.parse('2025-12-31') } },
    )
    r.save!(validate: false)
    r.update_column(:precalculated_data, precalculated_data)
    r
  end

  before do
    # GrdaWarehouse::Shape classes memoize their state-code lookup on the
    # class object itself (not Rails.cache), so it survives another spec
    # file's transaction rollback and can leak a stale (pre-fixture) empty
    # result in here. Force a fresh lookup for this run.
    GrdaWarehouse::Shape::Town.instance_variable_set(:@my_fips_state_codes, nil)
    Rails.cache.clear

    state = GrdaWarehouse::Shape::State.create!(stusps: 'MA', geoid: '25')
    GrdaWarehouse::Shape::Town.create!(town: 'ABINGTON', statefp: state.geoid, geom: 'SRID=4326;MULTIPOLYGON(((-71.5 42.0, -71.4 42.0, -71.4 42.1, -71.5 42.1, -71.5 42.0)))')
    GrdaWarehouse::Shape::Town.create!(town: 'ACTON', statefp: state.geoid, geom: 'SRID=4326;MULTIPOLYGON(((-71.3 42.0, -71.2 42.0, -71.2 42.1, -71.3 42.1, -71.3 42.0)))')
    PublicReports::Setting.first_or_create.update!(map_type: 'place')

    collection.set_viewables(reports: [report_definition.id])
    setup_access_control(user, role, collection)
    sign_in(user)
  end

  let(:sections) { [:summary, :pit, :entering_exiting, :who, :race, :map, :raw] }

  sections_for_iteration = [:summary, :pit, :entering_exiting, :who, :race, :map, :raw]
  sections_for_iteration.each do |section|
    it "returns 200 for the #{section} section" do
      get send("#{section}_public_reports_warehouse_reports_state_level_homelessness_path", report)
      expect(response).to have_http_status(:ok)
    end
  end

  it 'renders a data table and an accessible mark on the pit and summary sections' do
    get pit_public_reports_warehouse_reports_state_level_homelessness_path(report)
    expect(response.body).to include('<table')
    expect(response.body).to include("role='img'")

    get summary_public_reports_warehouse_reports_state_level_homelessness_path(report)
    expect(response.body).to include('stat-tile')
  end

  it 'embeds the who JSON blob on who, race and raw' do
    [:who, :race, :raw].each do |section|
      get send("#{section}_public_reports_warehouse_reports_state_level_homelessness_path", report)
      expect(response.body).to include('data-who-data')
    end
  end

  it 'embeds the town-map JSON blob on map and raw' do
    [:map, :raw].each do |section|
      get send("#{section}_public_reports_warehouse_reports_state_level_homelessness_path", report)
      expect(response.body).to include('data-town-map-data')
    end
  end

  it 'never loads chart assets from a CDN' do
    sections.each do |section|
      get send("#{section}_public_reports_warehouse_reports_state_level_homelessness_path", report)
      expect(response.body).not_to include('cdn.jsdelivr')
      expect(response.body).not_to include('unpkg')
    end
  end

  it 'produces non-nil markup for every section via as_html + html_section, which the S3 publish path depends on' do
    report.update!(html: report.as_html)
    report.sections.each do |section|
      expect(report.html_section(section)).to be_present
    end
  end
end
