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
    report.update_column(:precalculated_data, data.to_json)
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

  it 'labels monthly PIT data by month and thins the month labels' do
    months = (1..12).map { |m| Date.new(2025, m, 1).strftime('%b %Y') }
    report, = report_with(PublicReports::PitByMonth, 'pit_by_month', { labels: months, series: [{ label: 'Sheltered', values: Array.new(12, 150) }, { label: 'Unsheltered', values: Array.new(12, 120) }] })
    page = page_for(raw_public_reports_warehouse_reports_pit_by_month_path(report))

    expect(page.at_css('.chart-data th[scope="col"]').text).to eq('Month')
    expect(page.css('text.chart-axis-label--minor').map(&:text)).to eq(months.values_at(1, 3, 5, 7, 9, 11))
  end

  it 'labels yearly PIT data by year with no thinned labels' do
    report, = report_with(PublicReports::PointInTime, 'point_in_time', { labels: ['2024', '2025'], series: [{ label: 'People', values: [140, 160] }] })
    page = page_for(raw_public_reports_warehouse_reports_point_in_time_path(report))

    expect([page.at_css('.chart-data th[scope="col"]').text, page.css('text.chart-axis-label--minor').size]).to eq(['Year', 0])
  end

  it 'asks for a re-run when a PIT report holds the pre-redesign array data' do
    report, = report_with(PublicReports::PointInTime, 'point_in_time', [['x', '2024-01-31', '2025-01-29'], ['Unique people experiencing homelessness', 1432, 1518]])
    page = page_for(raw_public_reports_warehouse_reports_point_in_time_path(report))

    expect(page.at_css('.container').text.strip).to eq('Re-run this report to view it in the new format.')
  end

  it 'renders the homeless count tile' do
    report, = report_with(PublicReports::HomelessCount, 'homeless_count', { count: 1_234, date_range: 'January 1, 2025 - December 31, 2025' })
    page = page_for(raw_public_reports_warehouse_reports_homeless_count_path(report))

    expect(page.text).to include('1234', 'January 1, 2025 - December 31, 2025')
  end
end
