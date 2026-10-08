###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'PublicReports raw pages', type: :request do
  include AccessControlSetup

  let(:user) { create(:acl_user) }
  let(:role) { create(:role, can_view_assigned_reports: true) }
  let(:collection) { create(:collection) }

  def report_with(klass, slug, data)
    definition = GrdaWarehouse::WarehouseReports::ReportDefinition.create!(report_group: 'Reports', url: "public_reports/warehouse_reports/#{slug}", name: slug, description: '')
    collection.set_viewables(reports: GrdaWarehouse::WarehouseReports::ReportDefinition.pluck(:id))
    report = klass.new(user: user, filter: { filters: { start: Date.parse('2024-01-01'), end: Date.parse('2025-12-31') } })
    report.save!(validate: false)
    report.update_columns(precalculated_data: data.to_json, completed_at: Time.zone.parse('2025-06-01 12:00'))
    [report, definition]
  end

  before do
    setup_access_control(user, role, collection)
    sign_in(user)
  end

  def page_for(path)
    get path
    expect(response).to have_http_status(:ok)
    Nokogiri::HTML(response.body)
  end

  it 'renders the PIT chart from billboard.js columns in the raw_public_report layout' do
    columns = [['x', '2024-01-31', '2025-01-29'], ['Unique people experiencing homelessness', 1432, 1518]]
    report, = report_with(PublicReports::PointInTime, 'point_in_time', columns)
    page = page_for(raw_public_reports_warehouse_reports_point_in_time_path(report))

    expect(page.css('script[src*="billboard.min.js"]').size).to eq(1)
  end

  it 'links the saved font stylesheet and uses the saved font family list as written' do
    PublicReports::Setting.first_or_create.update!(font_url: '//fonts.googleapis.com/css?family=Lato', font_family_0: '"Lato", Arial')
    report, = report_with(PublicReports::HomelessCount, 'homeless_count', { count: 1_234, date_range: 'January 1, 2025 - December 31, 2025' })
    page = page_for(raw_public_reports_warehouse_reports_homeless_count_path(report))

    expect(page.at_css('link[href*="fonts.googleapis.com"]')['href']).to eq('//fonts.googleapis.com/css?family=Lato')
    expect(page.css('style').map(&:text).join).to include('font-family: "Lato", Arial, sans-serif;')
  end

  it 'falls back to the default fonts when stored font values fail the CSS formats' do
    PublicReports::Setting.first_or_create.update_columns(
      font_url: 'https://evil.example/x.css',
      font_family_0: 'x}</style><script>alert(1)</script>',
      font_size_0: '2rem;}</style>',
      font_weight_0: '700;}</style>',
    )
    report, = report_with(PublicReports::HomelessCount, 'homeless_count', { count: 1_234, date_range: 'January 1, 2025 - December 31, 2025' })
    page = page_for(raw_public_reports_warehouse_reports_homeless_count_path(report))
    css = page.css('style').map(&:text).join

    expect(page.css('script').map(&:text).join).not_to include('alert(1)')
    expect(page.css('link[rel="stylesheet"]').map { |link| link['href'] }).not_to include('https://evil.example/x.css')
    expect(css).to include('font-family: Poppins, sans-serif;', 'font-weight: 300;', 'font-size: 1rem;')
  end

  it 'renders the homeless count as a plain count and date range' do
    report, = report_with(PublicReports::HomelessCount, 'homeless_count', { count: 1_234, date_range: 'January 1, 2025 - December 31, 2025' })
    page = page_for(raw_public_reports_warehouse_reports_homeless_count_path(report))

    expect([page.at_css('.housed-total-count').text, page.at_css('.housed-total-count-date-range').text]).to eq(['1234', 'January 1, 2025 - December 31, 2025'])
  end
end
