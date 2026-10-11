###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PublicReports::StateDashboard::WhoData, type: :model do
  let(:user) { create(:acl_user) }
  let(:role) { create(:role, can_view_assigned_reports: true) }
  let(:report) do
    PublicReports::StateDashboard.new(
      user: user,
      filter: { filters: { start: Date.parse('2024-01-01'), end: Date.parse('2025-12-31'), project_type_numbers: [1] } },
    )
  end
  let(:white_label) { HudHelper.util.races(multi_racial: true)['White'] }

  before do
    travel_to(Date.parse('2026-06-15'))
    setup_access_control(user, role, Collection.system_collection(:data_sources))
    # Census data is loaded from the Census API, so the test supplies the figures.
    white_by_year = { 2024 => 100, 2025 => 600 }
    allow(report.geography).to receive(:population_by_race) do |year:, race_code: 'All'|
      case race_code
      when 'All' then 1_000
      when 'White' then white_by_year.fetch(year)
      else 0
      end
    end
  end

  after { travel_back }

  it 'compares the race chart with census figures for the last period year only' do
    race = described_class.new(report).to_h[:race]

    expect(race[:overall][race[:labels].index(white_label)]).to eq(60.0)
    expect(report.geography).not_to have_received(:population_by_race).with(hash_including(year: 2024))
  end
end
