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
      expect(page.at_css('.heading-with-icon a.info-icon')['class'].split).to include('info-icon--below')
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

  it 'points every change-time-period link at the who period select' do
    get who_public_reports_warehouse_reports_state_level_homelessness_path(report)
    page = Nokogiri::HTML(response.body)

    expect(page.at_css('select#who-period-select')&.[]('data-who-period')).not_to be_nil
    hrefs = page.css('.who-controls__period-note a').map { |a| a['href'] }
    expect(hrefs).to eq(['#who-period-select'] * 4)
  end

  it 'keeps the town map period select id' do
    get map_public_reports_warehouse_reports_state_level_homelessness_path(report)
    expect(Nokogiri::HTML(response.body).css('select#town-map-period').size).to eq(1)
  end

  context 'when the report owner no longer exists' do
    let(:role) { create(:role, can_view_assigned_reports: true, can_view_all_reports: true) }

    it 'renders the data note' do
      report.update_column(:user_id, nil)

      get summary_public_reports_warehouse_reports_state_level_homelessness_path(report)

      expect(Nokogiri::HTML(response.body).css('.data-note').map(&:text).uniq).to eq(['Data updated through Dec 31, 2025'])
    end
  end

  it 'replaces the map with a re-run message when the map type changed after the report ran' do
    PublicReports::Setting.first.update!(map_type: 'county')

    get map_public_reports_warehouse_reports_state_level_homelessness_path(report)
    page = Nokogiri::HTML(response.body)

    expect([page.css('[data-component="town-map"]').size, page.at_css('.town-map-stale')&.text&.strip]).to eq([0, 'The map type changed after this report ran. Re-run this report to view the map.'])
  end

  describe 'page structure' do
    it 'gives each topic on the raw page its own labelled section and h2' do
      get raw_public_reports_warehouse_reports_state_level_homelessness_path(report)
      page = Nokogiri::HTML(response.body)
      labels = page.css('section[aria-labelledby]').map { |s| s['aria-labelledby'] }

      expect(labels).to eq(['summary-heading', 'trends-heading', 'need-heading', 'who-heading'])
      labels.each { |id| expect(page.at_css("section h2##{id}")).not_to be_nil }
      expect(page.css('section:not([aria-labelledby])')).to be_empty
    end

    it 'wraps the raw summary tiles in a card and leaves the standalone summary without one' do
      get raw_public_reports_warehouse_reports_state_level_homelessness_path(report)
      expect(Nokogiri::HTML(response.body).css('section.stat-summary > .card > .stat-grid').size).to eq(1)

      get summary_public_reports_warehouse_reports_state_level_homelessness_path(report)
      page = Nokogiri::HTML(response.body)
      expect(page.css('section.stat-summary.stat-summary--standalone > .stat-grid').size).to eq(1)
      expect(page.css('.card')).to be_empty
    end

    it 'stacks the trend charts and states the partial-year note once' do
      get pit_public_reports_warehouse_reports_state_level_homelessness_path(report)
      page = Nokogiri::HTML(response.body)

      expect(page.css('.chart-grid--stack > figure.chart--line').size).to eq(2)
      expect(page.css('#trends-heading ~ p.note').size).to eq(1)
      expect(page.css('.chart-note')).to be_empty
    end

    it 'shows only the entering and exiting chart on that section' do
      get entering_exiting_public_reports_warehouse_reports_state_level_homelessness_path(report)
      titles = Nokogiri::HTML(response.body).css('figure.chart--line figcaption').map { |f| f.text.strip }

      expect(titles).to eq(['Total Number of People Entering and Exiting Homelessness'])
    end

    it 'ends each raw-page section with its own data note and none outside the container' do
      get raw_public_reports_warehouse_reports_state_level_homelessness_path(report)
      page = Nokogiri::HTML(response.body)
      notes = page.css('section > p.data-note, section .card > p.data-note').map(&:text)

      expect(notes).to eq(['Data updated through Dec 31, 2025'] * 4)
      expect(page.css('body > p.data-note')).to be_empty
    end

    it 'adds the published date after the glossary on the raw page' do
      report.update_column(:completed_at, Time.zone.parse('2026-01-05 10:00'))
      get raw_public_reports_warehouse_reports_state_level_homelessness_path(report)

      expect(Nokogiri::HTML(response.body).css('.container > p.data-note').map(&:text)).to eq(['Date published: Jan  5, 2026'])
    end
  end

  describe 'server-rendered who charts' do
    let(:page) do
      get who_public_reports_warehouse_reports_state_level_homelessness_path(report)
      Nokogiri::HTML(response.body)
    end

    it 'renders the current period of each donut with labelled segments and a table' do
      donut = page.at_css('figure.chart--donut[data-donut-id="all-people"]')

      expect(donut.at_css('svg title').text).to eq('All People: 19,000 People')
      segments = donut.css('circle.donut-segment')
      expect(segments.map { |s| s['aria-label'] }).to eq(['All People, Sheltered: 85%', 'All People, Unsheltered: 15%'])
      expect(segments.map { |s| [s['stroke-dasharray'], s['stroke-dashoffset']] }).to eq([['85 15', '25'], ['15 85', '-60']])
      expect(donut.css('.chart-data table tbody tr').map { |tr| tr.text.squish }).to eq(['Sheltered People 85%', 'Unsheltered People 15%'])
    end

    it 'reports a suppressed donut total as 100 or fewer' do
      expect(page.at_css('figure.chart--donut[data-donut-id="veterans"] svg title').text).to eq('Veterans: 100 or fewer Veterans')
    end

    it 'renders the household-type bar with contrast-checked inline labels' do
      chart = page.at_css('.chart--composition-bar[data-chart-id="household-type"][role="group"]')
      segments = chart.css('.stacked-bar__segment')

      expect(chart.at_css("p.chart-title##{chart['aria-labelledby']}").text).to eq('13,755 Households')
      expect(segments.map { |s| s['aria-label'] }).to eq(['Adult Only: 79%', 'Adults with Children: 20%', 'Children-Only Households: 1%'])
      expect(segments.first.at_css('span')['style']).to eq('color:#fff')
      expect(segments.last.at_css('span')).to be_nil
      expect(segments.last['style']).to include('box-shadow:inset 0 0 0 1px var(--color-ink)')
    end

    it 'renders both race bars, leaving out categories with no value but keeping them in the table' do
      chart = page.at_css('.chart--stacked-bar[data-chart-id="race"][role="group"]')
      bars = chart.css('.stacked-bar').to_h { |bar| [bar.at_css('.stacked-bar__label').text, bar.css('.stacked-bar__segment').map { |s| s['aria-label'] }] }

      expect(chart.at_css('p#chart-title-race').text).to eq('19,914 People')
      expect(bars).to eq(
        'Homeless Population' => ['Homeless Population, White: 44.5%', 'Homeless Population, Other or Unknown: 0.9%'],
        'Overall Population' => ['Overall Population, White: 71.4%'],
      )
      expect(chart.css('tbody tr').map { |tr| tr.css('th, td').map { |c| c.text.squish } }).to eq([['White', '44.5%', '71.4%'], ['Other or Unknown', '0.9%', '—']])
    end

    it 'renders race bars from reports that stored census shares as strings' do
      stored = JSON.parse(precalculated_data)
      stored['who']['race']['overall'] = ['71.4', nil]
      report.update_column(:precalculated_data, stored.to_json)

      bar = page.at_css('.chart--stacked-bar[data-chart-id="race"] .stacked-bar[data-key="overallPct"]')
      expect(bar.css('.stacked-bar__segment').map { |s| s['aria-label'] }).to eq(['Overall Population, White: 71.4%'])
    end
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
