###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'PublicReports::WarehouseReports::StateDashboard sections', type: :request do
  include AccessControlSetup

  let(:user) { create(:acl_user) }
  let(:role) { create(:role, can_view_assigned_reports: true) }
  let(:collection) { create(:collection) }
  let!(:report_definition) do
    GrdaWarehouse::WarehouseReports::ReportDefinition.create!(
      report_group: 'Reports',
      url: 'public_reports/warehouse_reports/state_dashboard',
      name: 'State-Level Homelessness Report',
      description: '',
    )
  end

  let(:precalculated_data) { File.read(Rails.root.join('spec/fixtures/files/public_reports/state_level_v2.json')) }

  let!(:report) do
    r = PublicReports::StateDashboard.new(
      user: user,
      filter: { filters: { start: Date.parse('2024-01-01'), end: Date.parse('2025-12-31') } },
    )
    r.save!(validate: false)
    r.update_column(:precalculated_data, precalculated_data)
    r
  end

  # Translation.translate reads the lowest-id row for a key, so a second row would be ignored.
  def write_glossary(text)
    Translation.where(key: PublicReports::StateDashboard::Glossary::TRANSLATION_KEY).order(:id).first_or_initialize.update!(text: text)
  end

  before do
    state = GrdaWarehouse::Shape::State.create!(stusps: 'MA', geoid: '25')
    GrdaWarehouse::Shape::Town.create!(town: 'ABINGTON', statefp: state.geoid, geom: 'SRID=4326;MULTIPOLYGON(((-71.5 42.0, -71.4 42.0, -71.4 42.1, -71.5 42.1, -71.5 42.0)))')
    GrdaWarehouse::Shape::Town.create!(town: 'ACTON', statefp: state.geoid, geom: 'SRID=4326;MULTIPOLYGON(((-71.3 42.0, -71.2 42.0, -71.2 42.1, -71.3 42.1, -71.3 42.0)))')
    PublicReports::Setting.first_or_create.update!(map_type: 'place')

    collection.set_viewables(reports: [report_definition.id])
    setup_access_control(user, role, collection)
    sign_in(user)
  end

  sections_for_iteration = [:summary, :pit, :entering_exiting, :who, :race, :map, :raw]
  it 'renders the race bars on the race section with no breakdown rows' do
    get race_public_reports_warehouse_reports_state_dashboard_path(report)
    page = Nokogiri::HTML(response.body)

    expect(page.css('[data-who-period-pane]:not([hidden]) .chart--stacked-bar[data-chart-id="race"] .stacked-bar__label').map(&:text)).to eq(['Homeless Population', 'Overall Population'])
    expect(page.css('.breakdown-row, .breakdown-heading')).to be_empty
  end

  it 'renders the PIT data table and the summary tiles from the stored data' do
    get pit_public_reports_warehouse_reports_state_dashboard_path(report)
    rows = Nokogiri::HTML(response.body).at_css('figure.chart--line table').css('tbody tr').map { |tr| tr.css('th, td').map { |cell| cell.text.strip } }
    expect(rows).to eq([['2024', '33,048'], ['2025*', '13,939']])

    get summary_public_reports_warehouse_reports_state_dashboard_path(report)
    expect(Nokogiri::HTML(response.body).css('.stat-tile__value').map { |value| value.text.strip }).to eq(['10,214', '13,939', '13%'])
  end

  describe 'who section periods' do
    let(:who) { JSON.parse(precalculated_data)['who'] }

    it 'renders every period, showing only the current one, with no JSON for scripts to rebuild charts from' do
      get who_public_reports_warehouse_reports_state_dashboard_path(report)
      page = Nokogiri::HTML(response.body)
      panes = page.css('[data-who-period-pane]')

      expect(panes.map { |pane| pane['data-who-period-pane'] }.uniq).to eq(who['periods'].each_index.map(&:to_s))
      expect(panes.reject { |pane| pane.key?('hidden') }.map { |pane| pane['data-who-period-pane'] }.uniq).to eq([who['currentIndex'].to_s])
      expect(page.css('[data-who-data]')).to be_empty
    end

    it 'keeps element ids unique across periods' do
      get raw_public_reports_warehouse_reports_state_dashboard_path(report)
      ids = Nokogiri::HTML(response.body).css('[id]').map { |el| el['id'] }

      expect(ids.tally.select { |_, count| count > 1 }).to eq({})
    end

    it 'shows the earlier period donut total in its own hidden pane' do
      get who_public_reports_warehouse_reports_state_dashboard_path(report)
      earlier = (who['currentIndex'] - 1).to_s
      title = Nokogiri::HTML(response.body).at_css(%([data-who-period-pane="#{earlier}"] figure.chart--donut[data-donut-id="all-people"] svg title))

      expect(title.text).to eq("#{who['donuts']['all-people']['title']}: #{PublicReports::StateDashboard::WhoCharts.format_total(who['donuts']['all-people']['totals'][earlier.to_i], who['donuts']['all-people']['unit'])}")
    end
  end

  it 'embeds the town-map JSON blob on map and raw with DB-sourced names escaped' do
    hostile = '</script><script>alert(1)</script>'
    stored = JSON.parse(precalculated_data)
    stored['map']['towns'][0] = hostile
    report.update_column(:precalculated_data, stored.to_json)

    [:map, :raw].each do |section|
      get send("#{section}_public_reports_warehouse_reports_state_dashboard_path", report)

      expect(response.body).not_to include('</script><script>alert'), section.to_s
      blob = Nokogiri::HTML(response.body).at_css('script[data-town-map-data]').text
      expect(JSON.parse(blob)['towns'].first).to eq(hostile), section.to_s
    end
  end

  it 'labels each town-map table row with a row header naming the town' do
    get map_public_reports_warehouse_reports_state_dashboard_path(report)
    rows = Nokogiri::HTML(response.body).css('[data-town-map-tbody] tr')

    expect(rows.map { |tr| tr.at_css('th[scope="row"]')&.text }).to match_array(JSON.parse(precalculated_data)['map']['towns'])
  end

  it 'fills a map path whose rate falls between band maxima with the next band up' do
    # Abington's current-period rate is 7.3, between the 0 and 10.0 bands.
    get map_public_reports_warehouse_reports_state_dashboard_path(report)
    abington = Nokogiri::HTML(response.body).at_css('path#town-abington')
    expect(abington['style']).to eq('fill:#D7E0E9')
  end

  it 'renders breakdown rows for every grouping' do
    get who_public_reports_warehouse_reports_state_dashboard_path(report)
    labels = Nokogiri::HTML(response.body).css('[data-who-period-pane]:not([hidden]) .breakdown-row__label').map(&:text)
    expect(labels).to contain_exactly('Persons Age 18 to 24', 'Persons over age 24', 'Fixture Gender Row', 'Fixture Race Row')
  end

  it 'marks both places the breakdown heading names the grouping' do
    get who_public_reports_warehouse_reports_state_dashboard_path(report)

    expect(Nokogiri::HTML(response.body).css('[data-who-grouping-label]').map(&:text)).to eq(['Household Type', 'Household Type'])
  end

  context 'when a chart segment is 0%' do
    before do
      stored = JSON.parse(precalculated_data)
      stored['who']['donuts']['all-people']['values'][1] = [100, 0]
      stored['who']['donuts']['household-type']['values'][1] = [80, 20, 0]
      report.update_column(:precalculated_data, stored.to_json)
    end

    it 'gives keyboard focus only to segments with a value, and keeps 0% rows in the data table' do
      get who_public_reports_warehouse_reports_state_dashboard_path(report)
      page = Nokogiri::HTML(response.body)
      focusable = page.css('[data-who-period-pane="1"] [tabindex="0"][aria-label]').map { |el| el['aria-label'] }

      expect(focusable).to include('All People, Sheltered: 100%', 'Adult Only: 80%')
      expect(focusable.grep(/: 0%\z/)).to eq([])
      expect(page.css('[data-who-period-pane="1"] .chart-data table').text).to include('Children-Only Households')
    end
  end

  it 'titles each section preview iframe on the edit page' do
    report.update_column(:completed_at, Time.current)
    get edit_public_reports_warehouse_reports_state_dashboard_path(report)
    titles = Nokogiri::HTML(response.body).css('iframe').map { |frame| frame['title'] }

    expect(titles).to eq(report.sections.map { |section| "#{report.instance_title} — #{section.to_s.humanize} preview" })
  end

  it 'shows a suppressed breakdown row as a redacted bar with no chronic percent' do
    get who_public_reports_warehouse_reports_state_dashboard_path(report)
    rows = Nokogiri::HTML(response.body).css('[data-who-period-pane]:not([hidden]) .breakdown-row')
    row = rows.find { |r| r.at_css('.breakdown-row__label').text == 'Persons over age 24' }

    expect(row.at_css('.breakdown-bar__segment--redacted')['aria-label']).to eq('Persons over age 24: sheltered/unsheltered breakdown unavailable for this group')
    expect(row.at_css('[data-row-chronic-full]').text).to eq('Chronically Homeless: not reported')
  end

  it 'links the summary heading to the glossary on summary and raw' do
    write_glossary('**Sheltered**: staying in ES, SH, or TH.')

    [:summary, :raw].each do |section|
      get send("#{section}_public_reports_warehouse_reports_state_dashboard_path", report)
      page = Nokogiri::HTML(response.body)
      expect(page.at_css('.heading-with-icon h2#summary-heading')&.text).to eq('Statewide summary')
      expect(page.at_css('.heading-with-icon a.info-icon')&.[]('href')).to eq('#glossary')
      expect(page.at_css('.heading-with-icon a.info-icon')['class'].split).to include('info-icon--below')
      expect(page.css('#glossary').size).to eq(1)
    end
  end

  it 'omits the glossary link when no glossary is configured' do
    get summary_public_reports_warehouse_reports_state_dashboard_path(report)
    page = Nokogiri::HTML(response.body)
    expect(page.at_css('h2#summary-heading')&.text).to eq('Statewide summary')
    expect(page.css('#glossary, a.info-icon')).to be_empty
  end

  describe 'per-term glossary links' do
    before do
      write_glossary(
        "### ES / SO / SH / TH\nEmergency Shelter, Street Outreach, Safe Haven, Transitional Housing.\n\n" \
        "### Unsheltered / Unsheltered Rate\nPeople sleeping in a place not meant for habitation.\n",
      )
    end

    it 'links both pit chart titles to the term, with the definition as a uniquely-identified tooltip' do
      get pit_public_reports_warehouse_reports_state_dashboard_path(report)
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
      get summary_public_reports_warehouse_reports_state_dashboard_path(report)
      icon = Nokogiri::HTML(response.body).at_css('.stat-tile__label a.info-icon')
      expect(icon&.[]('href')).to eq('#glossary-unsheltered-unsheltered-rate')
    end

    it 'omits a term link when the glossary does not define that term' do
      write_glossary("### Unsheltered / Unsheltered Rate\nPeople outside.\n")
      get pit_public_reports_warehouse_reports_state_dashboard_path(report)
      expect(Nokogiri::HTML(response.body).css('.chart-title a.info-icon')).to be_empty
    end
  end

  it 'gives the embed snippet a listener for the height the published page posts' do
    snippet = Nokogiri::HTML.fragment(report.generate_embed_code_for(:pit))
    iframe = snippet.at_css('iframe')
    expect(iframe['src']).to eq(report.generate_publish_url_for(:pit))
    expect(iframe['title']).to eq("#{report.instance_title} -- Pit")
    expect(snippet.at_css('script').text).to include("getElementById('#{iframe['id']}')")
    expect(snippet.at_css('script').text).to include("'public-report-height'")
    expect(report.generate_embed_code_for(:who)).not_to include("id='#{iframe['id']}'")

    get pit_public_reports_warehouse_reports_state_dashboard_path(report)
    expect(response.body).to include('type: "public-report-height"')
  end

  it 'inlines every script and stylesheet' do
    sections_for_iteration.each do |section|
      get send("#{section}_public_reports_warehouse_reports_state_dashboard_path", report)

      expect(Nokogiri::HTML(response.body).css('script[src], link[rel="stylesheet"]').map(&:to_s)).to eq([]), section.to_s
    end
  end

  it 'splits as_html into one self-contained section per template, which the S3 publish path depends on' do
    landmarks = {
      pit: 'figure.chart--line',
      entering_exiting: 'figure.chart--line',
      summary: '.stat-tile__value',
      map: '[data-component="town-map"]',
      who: '.breakdown-row',
      race: '.chart--stacked-bar[data-chart-id="race"]',
      raw: 'section[aria-labelledby="who-heading"]',
    }
    report.update!(html: report.as_html)

    expect(report.html.scan('SECTION START').size).to eq(report.sections.size)
    report.sections.each do |section|
      fragment = report.html_section(section)
      expect(fragment.scan("<!-- SECTION START #{section} -->").size).to eq(1), section.to_s
      expect(fragment.scan('SECTION START').size).to eq(1), section.to_s
      expect(Nokogiri::HTML.fragment(fragment).at_css(landmarks.fetch(section))).not_to be_nil, section.to_s
    end
  end

  it 'sets a dash pattern only on line series after the first' do
    get pit_public_reports_warehouse_reports_state_dashboard_path(report)
    polylines = Nokogiri::HTML(response.body).css('figure.chart--line polyline')

    expect(polylines.map { |p| p['stroke-dasharray'] }).to eq([nil, nil, '7,4'])
  end

  it 'points every change-time-period link at the who period select' do
    get who_public_reports_warehouse_reports_state_dashboard_path(report)
    page = Nokogiri::HTML(response.body)

    expect(page.at_css('select#who-period-select')&.[]('data-who-period')).not_to be_nil
    hrefs = page.css('.who-controls__period-note a').map { |a| a['href'] }
    expect(hrefs).to eq(['#who-period-select'] * 4)
  end

  it 'keeps the town map period select id' do
    get map_public_reports_warehouse_reports_state_dashboard_path(report)
    expect(Nokogiri::HTML(response.body).css('select#town-map-period').size).to eq(1)
  end

  context 'when the report owner was deleted' do
    let(:role) { create(:role, can_view_assigned_reports: true, can_view_all_reports: true) }
    let(:owner) { create(:acl_user) }

    before do
      report.update_column(:user_id, owner.id)
      owner.destroy
    end

    it 'lists the report in the history table' do
      get public_reports_warehouse_reports_state_dashboard_index_path

      expect(response).to have_http_status(:ok)
      expect(Nokogiri::HTML(response.body).css('td.report-parameters').size).to eq(1)
    end
  end

  it 'replaces the map with a re-run message when the map type changed after the report ran' do
    PublicReports::Setting.first.update!(map_type: 'county')

    get map_public_reports_warehouse_reports_state_dashboard_path(report)
    page = Nokogiri::HTML(response.body)

    expect([page.css('[data-component="town-map"]').size, page.at_css('.town-map-stale')&.text&.strip]).to eq([0, 'The map type changed after this report ran. Re-run this report to view the map.'])
  end

  describe 'page structure' do
    it 'gives each topic on the raw page its own labelled section and h2' do
      get raw_public_reports_warehouse_reports_state_dashboard_path(report)
      page = Nokogiri::HTML(response.body)
      labels = page.css('section[aria-labelledby]').map { |s| s['aria-labelledby'] }

      expect(labels).to eq(['summary-heading', 'trends-heading', 'need-heading', 'who-heading'])
      labels.each { |id| expect(page.at_css("section h2##{id}")).not_to be_nil }
      expect(page.css('section:not([aria-labelledby])')).to be_empty
    end

    it 'wraps the raw summary tiles in a card and leaves the standalone summary without one' do
      get raw_public_reports_warehouse_reports_state_dashboard_path(report)
      expect(Nokogiri::HTML(response.body).css('section.stat-summary > .card > .stat-grid').size).to eq(1)

      get summary_public_reports_warehouse_reports_state_dashboard_path(report)
      page = Nokogiri::HTML(response.body)
      expect(page.css('section.stat-summary.stat-summary--standalone > .stat-grid').size).to eq(1)
      expect(page.css('.card')).to be_empty
    end

    it 'stacks the trend charts and states the partial-year note once' do
      get pit_public_reports_warehouse_reports_state_dashboard_path(report)
      page = Nokogiri::HTML(response.body)

      expect(page.css('.chart-grid--stack > figure.chart--line').size).to eq(2)
      expect(page.css('#trends-heading ~ p.note').size).to eq(1)
      expect(page.css('.chart-note')).to be_empty
    end

    it 'shows only the entering and exiting chart on that section' do
      get entering_exiting_public_reports_warehouse_reports_state_dashboard_path(report)
      titles = Nokogiri::HTML(response.body).css('figure.chart--line figcaption').map { |f| f.text.strip }

      expect(titles).to eq(['Total Number of People Entering and Exiting Homelessness'])
    end

    it 'ends each raw-page section with its own data note and none outside the container' do
      get raw_public_reports_warehouse_reports_state_dashboard_path(report)
      page = Nokogiri::HTML(response.body)
      notes = page.css('section > p.data-note, section .card > p.data-note').map(&:text)

      expect(notes).to eq(['Data updated through Dec 31, 2025'] * 4)
      expect(page.css('body > p.data-note')).to be_empty
    end

    it 'adds the published date after the glossary on the raw page' do
      report.update_column(:completed_at, Time.zone.parse('2026-01-05 10:00'))
      get raw_public_reports_warehouse_reports_state_dashboard_path(report)

      expect(Nokogiri::HTML(response.body).css('.container > p.data-note').map(&:text)).to eq(['Date published: Jan  5, 2026'])
    end
  end

  describe 'server-rendered who charts' do
    let(:page) do
      get who_public_reports_warehouse_reports_state_dashboard_path(report)
      Nokogiri::HTML(response.body)
    end

    it 'renders the current period of each donut with labelled segments and a table' do
      donut = page.at_css('[data-who-period-pane]:not([hidden]) figure.chart--donut[data-donut-id="all-people"]')

      expect(donut.at_css('svg title').text).to eq('All People: 19,000 People')
      segments = donut.css('circle.donut-segment')
      expect(segments.map { |s| s['aria-label'] }).to eq(['All People, Sheltered: 85%', 'All People, Unsheltered: 15%'])
      expect(segments.map { |s| [s['stroke-dasharray'], s['stroke-dashoffset']] }).to eq([['85 15', '25'], ['15 85', '-60']])
      expect(donut.css('.chart-data table tbody tr').map { |tr| tr.text.squish }).to eq(['Sheltered People 85%', 'Unsheltered People 15%'])
    end

    it 'reports a suppressed donut total as 100 or fewer' do
      expect(page.at_css('[data-who-period-pane]:not([hidden]) figure.chart--donut[data-donut-id="veterans"] svg title').text).to eq('Veterans: 100 or fewer Veterans')
    end

    it 'renders the household-type bar with contrast-checked inline labels' do
      chart = page.at_css('[data-who-period-pane]:not([hidden]) .chart--composition-bar[data-chart-id="household-type"][role="group"]')
      segments = chart.css('.stacked-bar__segment')

      expect(chart.at_css("p.chart-title##{chart['aria-labelledby']}").text).to eq('13,755 Households')
      expect(segments.map { |s| s['aria-label'] }).to eq(['Adult Only: 79%', 'Adults with Children: 20%', 'Children-Only Households: 1%'])
      expect(segments.first.at_css('span')['style']).to eq('color:#fff')
      expect(segments.last.at_css('span')).to be_nil
      expect(segments.last['style']).to include('box-shadow:inset 0 0 0 1px var(--color-ink)')
    end

    it 'renders both race bars, leaving out categories with no value but keeping them in the table' do
      chart = page.at_css('[data-who-period-pane]:not([hidden]) .chart--stacked-bar[data-chart-id="race"][role="group"]')
      bars = chart.css('.stacked-bar').to_h { |bar| [bar.at_css('.stacked-bar__label').text, bar.css('.stacked-bar__segment').map { |s| s['aria-label'] }] }

      expect(chart.at_css('p.chart-title').text).to eq('19,914 People')
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

      bar = page.at_css('[data-who-period-pane]:not([hidden]) .chart--stacked-bar[data-chart-id="race"] .stacked-bar[data-key="overallPct"]')
      expect(bar.css('.stacked-bar__segment').map { |s| s['aria-label'] }).to eq(['Overall Population, White: 71.4%'])
    end
  end

  describe 'design tokens' do
    it 'defines every custom property the raw page uses' do
      get raw_public_reports_warehouse_reports_state_dashboard_path(report)
      css = Nokogiri::HTML(response.body).css('style').map(&:text).join("\n")
      used = css.scan(/var\((--[\w-]+)/).flatten.uniq
      defined = css.scan(/(--[\w-]+)\s*:/).flatten.uniq

      expect(used - defined).to be_empty
    end
  end

  describe 'authorization' do
    after { Delayed::Job.delete_all }

    context 'for a report-viewing user who does not own the report' do
      let(:other_user) { create(:acl_user) }

      before do
        setup_access_control(other_user, role, collection)
        sign_out(user)
        sign_in(other_user)
      end

      it 'lists only the user\'s own reports in the history table' do
        own = PublicReports::StateDashboard.new(
          user: other_user,
          filter: { filters: { start: Date.parse('2024-01-01'), end: Date.parse('2025-12-31') } },
          version_slug: 'mine',
        )
        own.save!(validate: false)
        report.update_column(:version_slug, 'theirs')

        get public_reports_warehouse_reports_state_dashboard_index_path

        rows = Nokogiri::HTML(response.body).css('.warehouse-reports__completed tbody tr')
        expect(rows.map { |row| row.at_css('td.text-center').text[/\((\w+)\)/, 1] }).to eq(['mine'])
      end

      it 'does not preview another user\'s report' do
        get summary_public_reports_warehouse_reports_state_dashboard_path(report)

        expect(response).to have_http_status(:not_found)
      end

      it 'does not queue publishing of another user\'s report' do
        expect do
          patch public_reports_warehouse_reports_state_dashboard_path(report), params: { public_report: { published_url: report.generate_publish_url } }
        end.not_to change(Delayed::Job, :count)

        expect(response).to have_http_status(:not_found)
        expect(report.reload.published_url).to be_nil
      end

      it 'does not destroy another user\'s report' do
        delete public_reports_warehouse_reports_state_dashboard_path(report)

        expect(response).to have_http_status(:not_found)
        expect(PublicReports::StateDashboard.exists?(report.id)).to be(true)
      end
    end

    context 'for a user whose collection has no State Dashboard report definition' do
      let(:outsider) { create(:acl_user) }

      before do
        setup_access_control(outsider, role, create(:collection))
        sign_out(user)
        sign_in(outsider)
      end

      it 'redirects away from the section preview' do
        get summary_public_reports_warehouse_reports_state_dashboard_path(report)

        expect(response).to redirect_to(outsider.my_root_path)
      end

      it 'redirects away from publishing without queuing a job' do
        expect do
          patch public_reports_warehouse_reports_state_dashboard_path(report), params: { public_report: { published_url: report.generate_publish_url } }
        end.not_to change(Delayed::Job, :count)

        expect(response).to redirect_to(outsider.my_root_path)
        expect(report.reload.published_url).to be_nil
      end
    end
  end

  describe 'PATCH update' do
    let(:s3) do
      Aws::S3::Client.new(
        credentials: Aws::Credentials.new('key', 'secret'),
        region: 'us-east-1',
        stub_responses: { delete_object: { delete_marker: true } },
      )
    end

    before { allow(AwsS3).to receive(:new).and_return(instance_double(AwsS3, client: s3)) }
    after { Delayed::Job.delete_all }

    it 'stores the folder and redirects to the report' do
      patch public_reports_warehouse_reports_state_dashboard_path(report), params: { public_report: { version_slug: 'coc-500' } }

      expect(response).to redirect_to(public_reports_warehouse_reports_state_dashboard_path(report))
      expect(report.reload.version_slug).to eq('coc-500')
    end

    it 'keeps the old folder and shows the error when the new one would leave the report folder' do
      report.update_columns(version_slug: 'state', completed_at: Time.current)

      patch public_reports_warehouse_reports_state_dashboard_path(report), params: { public_report: { version_slug: "../state'" } }

      expect(report.reload.version_slug).to eq('state')
      expect(response.body).to include('must be folder names of letters, numbers, dashes and underscores, separated by single slashes')
    end

    it 'queues publishing without publishing inline' do
      expect do
        patch public_reports_warehouse_reports_state_dashboard_path(report), params: { public_report: { published_url: report.generate_publish_url } }
      end.to change(Delayed::Job, :count).by(1)

      expect(response).to redirect_to(public_reports_warehouse_reports_state_dashboard_path(report))
      expect(flash[:notice]).to eq('Report publishing queued, please check the public link in a few minutes.')
      expect(Delayed::Job.last.handler).to include('method_name: :publish!')
      expect(report.reload.published_url).to be_nil
      expect(s3.api_requests).to eq([])
    end

    context 'with a published report' do
      before do
        report.update_columns(version_slug: 'state')
        report.update_columns(published_url: report.generate_publish_url, embed_code: '<iframe></iframe>', html: '<html></html>', state: 'published')
      end

      it 'unpublishes when the token matches the publish url' do
        patch public_reports_warehouse_reports_state_dashboard_path(report), params: { public_report: { unpublish: report.reload.generate_publish_url } }

        expect(response).to redirect_to(public_reports_warehouse_reports_state_dashboard_path(report))
        expect(flash[:notice]).to eq('Report has been unpublished.')
        expect(report.reload.attributes.values_at('published_url', 'embed_code', 'html', 'state')).to eq([nil, nil, nil, 'pre-calculated'])
        expect(s3.api_requests.map { |r| r[:operation_name] }).to eq([:delete_object] * report.sections.size)
      end

      it 'leaves a published report alone when the unpublish token does not match' do
        patch public_reports_warehouse_reports_state_dashboard_path(report), params: { public_report: { unpublish: 'https://example.test/not-this-report/index.html' } }

        expect(response).to redirect_to(edit_public_reports_warehouse_reports_state_dashboard_path(report))
        expect(report.reload.published_url).to eq(report.generate_publish_url)
        expect(s3.api_requests).to eq([])
      end
    end
  end
end
