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
    expect(page.css('script').map(&:text).join).to include("columns: #{columns.to_json}")
  end

  it 'renders the homeless count as a plain count and date range' do
    report, = report_with(PublicReports::HomelessCount, 'homeless_count', { count: 1_234, date_range: 'January 1, 2025 - December 31, 2025' })
    page = page_for(raw_public_reports_warehouse_reports_homeless_count_path(report))

    expect([page.at_css('.housed-total-count').text, page.at_css('.housed-total-count-date-range').text]).to eq(['1234', 'January 1, 2025 - December 31, 2025'])
  end
end
