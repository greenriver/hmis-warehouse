###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'nokogiri'

# The cards are appended over XHR by App.Sections.Loader, so an inline <script> would carry
# the XHR's CSP nonce rather than the page's and be blocked. The full report needs CoC shapes
# with no factories here, so this renders the partial against a details-shaped hash.
RSpec.describe 'warehouse_reports/overlapping_coc_utilization/_client_card', type: :view do
  let(:enrollments) { [{ 'coc' => 'AA-000', 'project_name' => 'Shelter', 'history' => [] }] }
  let(:cocs) { [{ 'code' => 'AA-000' }] }

  before do
    assign(:report, double(time_range: [Date.new(2025, 1, 1), Date.new(2025, 12, 31)]))
    assign(:details, { cocs: cocs })
    without_partial_double_verification do
      allow(view).to receive(:can_access_some_version_of_clients?).and_return(false)
    end
  end

  it 'passes the chart data to the Stimulus controller' do
    render partial: 'warehouse_reports/overlapping_coc_utilization/client_card', locals: { data: { client_id: 1, enrollments: enrollments }, id: 0 }

    html = Nokogiri::HTML(rendered)
    expect(view.content_for(:page_js)).to be_blank

    chart = html.at_css('#j-client-0[data-controller="client-timeline-chart"]')
    expect(JSON.parse(chart['data-client-timeline-chart-enrollments-value'])).to eq(enrollments)
    expect(JSON.parse(chart['data-client-timeline-chart-domain-value'])).to eq(['2025-01-01', '2025-12-31'])
    expect(JSON.parse(chart['data-client-timeline-chart-cocs-value'])).to eq(cocs)
  end
end
