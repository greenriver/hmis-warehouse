###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PublicReports::StateLevelHomelessness, type: :model do
  it 'labels a small household count "Under 100", where the dashboard says "100 or fewer"' do
    counts = { 'homeless_households' => 5 }

    expect(
      [described_class.new.enforce_min_threshold(counts, 'homeless_households'), PublicReports::StateDashboard.new.enforce_min_threshold(counts, 'homeless_households')],
    ).to eq(['Under 100', '100 or fewer'])
  end

  # filter_object moves the end date to the end of its month, so the boundary is a whole month.
  it 'accepts a span of exactly twelve months and rejects eleven' do
    user = create(:acl_user)
    reports = [['2025-01-01', '2025-12-31'], ['2025-01-01', '2025-11-30']].map do |start, finish|
      described_class.new(user: user, filter: { filters: { start: Date.parse(start), end: Date.parse(finish), project_type_numbers: [1] } })
    end

    expect(reports.map(&:valid?)).to eq([true, false])
  end

  it 'snaps need-map rates to the top of their color range and hides small counts' do
    report = described_class.new
    report.settings.update!((0..7).to_h { |i| ["color_#{i}", format('#%06x', 0x111111 * (i + 1))] })
    top = report.map_colors.values.second[:range].last
    data = { 'homeless_map' => { '2025-01-01' => { 'ROCKPORT' => { count: 62, overall_population: 500, rate: 0.5 } } } }

    town = report.enforce_min_threshold(data, 'need_map')['homeless_map']['2025-01-01']['ROCKPORT']

    expect([town[:count], town[:rate]]).to eq(['less than 100', top])
  end
end
