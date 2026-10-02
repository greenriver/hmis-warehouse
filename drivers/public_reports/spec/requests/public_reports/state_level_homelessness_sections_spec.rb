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

  it 'fills a map path whose rate falls between band maxima with the next band up' do
    # Abington's current-period rate is 7.3, between the 0 and 10.0 bands.
    get map_public_reports_warehouse_reports_state_level_homelessness_path(report)
    abington = Nokogiri::HTML(response.body).at_css('path#town-abington')
    expect(abington['style']).to eq('fill:#D7E0E9')
  end

  it 'renders breakdown rows for every grouping' do
    get who_public_reports_warehouse_reports_state_level_homelessness_path(report)
    labels = Nokogiri::HTML(response.body).css('.breakdown-row__label').map(&:text)
    expect(labels).to contain_exactly('Persons Age 18 to 24', 'Persons over age 24', 'Fixture Gender Row', 'Fixture Race Row')
  end

  it 'links the summary heading to the glossary on summary and raw' do
    Translation.create!(key: 'Public Report Glossary', text: '**Sheltered**: staying in ES, SH, or TH.')

    [:summary, :raw].each do |section|
      get send("#{section}_public_reports_warehouse_reports_state_level_homelessness_path", report)
      page = Nokogiri::HTML(response.body)
      expect(page.at_css('.heading-with-icon h2#summary-heading')&.text).to eq('Statewide summary')
      expect(page.at_css('.heading-with-icon a.info-icon')&.[]('href')).to eq('#glossary')
      expect(page.css('#glossary').size).to eq(1)
    end
  end

  it 'omits the glossary link when no glossary is configured' do
    get summary_public_reports_warehouse_reports_state_level_homelessness_path(report)
    page = Nokogiri::HTML(response.body)
    expect(page.at_css('h2#summary-heading')&.text).to eq('Statewide summary')
    expect(page.css('#glossary, a.info-icon')).to be_empty
  end

  describe 'per-term glossary links' do
    before do
      Translation.create!(
        key: 'Public Report Glossary',
        text: "### ES / SO / SH / TH\nEmergency Shelter, Street Outreach, Safe Haven, Transitional Housing.\n\n" \
              "### Unsheltered / Unsheltered Rate\nPeople sleeping in a place not meant for habitation.\n",
      )
    end

    it 'links both pit chart titles to the term, with the definition as a uniquely-identified tooltip' do
      get pit_public_reports_warehouse_reports_state_level_homelessness_path(report)
      page = Nokogiri::HTML(response.body)

      expect(page.at_css('#glossary dt#glossary-es-so-sh-th')&.text).to eq('ES / SO / SH / TH')
      icons = page.css('.chart-title a.info-icon')
      expect(icons.map { |a| a['href'] }).to eq(['#glossary-es-so-sh-th', '#glossary-es-so-sh-th'])
      tooltip_ids = icons.map { |a| a['aria-describedby'] }
      expect(tooltip_ids.uniq.size).to eq(2)
      tooltip_ids.each do |id|
        expect(page.at_css("##{id}")&.text).to eq('Emergency Shelter, Street Outreach, Safe Haven, Transitional Housing.')
      end
    end

    it 'links the unsheltered tile to its term' do
      get summary_public_reports_warehouse_reports_state_level_homelessness_path(report)
      icon = Nokogiri::HTML(response.body).at_css('.stat-tile__label a.info-icon')
      expect(icon&.[]('href')).to eq('#glossary-unsheltered-unsheltered-rate')
    end

    it 'omits a term link when the glossary does not define that term' do
      Translation.find_by(key: 'Public Report Glossary').update!(text: "### Unsheltered / Unsheltered Rate\nPeople outside.\n")
      get pit_public_reports_warehouse_reports_state_level_homelessness_path(report)
      expect(Nokogiri::HTML(response.body).css('.chart-title a.info-icon')).to be_empty
    end
  end

  it 'gives the embed snippet a listener for the height the published page posts' do
    snippet = Nokogiri::HTML.fragment(report.generate_embed_code_for(:pit))
    iframe = snippet.at_css('iframe')
    expect(iframe['src']).to eq(report.generate_publish_url_for(:pit))
    expect(snippet.at_css('script').text).to include("getElementById('#{iframe['id']}')")
    expect(snippet.at_css('script').text).to include("'public-report-height'")
    expect(report.generate_embed_code_for(:who)).not_to include("id='#{iframe['id']}'")

    get pit_public_reports_warehouse_reports_state_level_homelessness_path(report)
    expect(response.body).to include('type: "public-report-height"')
  end

  it 'keeps deployment-specific wording out of the map script' do
    get map_public_reports_warehouse_reports_state_level_homelessness_path(report)
    expect(response.body).not_to include('THDSN')
    expect(response.body).not_to include('per 10,000 residents by county')
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

  it 'sets a dash pattern only on line series after the first' do
    get pit_public_reports_warehouse_reports_state_level_homelessness_path(report)
    polylines = Nokogiri::HTML(response.body).css('figure.chart--line polyline')

    expect(polylines.map { |p| p['stroke-dasharray'] }).to eq([nil, nil, '7,4'])
  end

  describe 'design tokens' do
    let(:base_css) { File.read(Rails.root.join('drivers/public_reports/lib/public_reports/assets/public_report.css')) }

    it 'defines every custom property the raw page uses' do
      get raw_public_reports_warehouse_reports_state_level_homelessness_path(report)
      css = Nokogiri::HTML(response.body).css('style').map(&:text).join("\n")
      used = css.scan(/var\((--[\w-]+)/).flatten.uniq
      defined = css.scan(/(--[\w-]+)\s*:/).flatten.uniq

      expect(used - defined).to be_empty
    end

    it 'leaves the themed tokens to the theme partial' do
      themed = File.read(Rails.root.join('drivers/public_reports/app/views/layouts/public_reports/_theme_css.haml')).scan(/(--[\w-]+):/).flatten
      base_defined = base_css.scan(/(--[\w-]+)\s*:/).flatten

      expect(base_defined & themed).to be_empty
    end
  end
end
