###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'PublicReports PIT chart data', type: :model do
  include AccessControlSetup

  let(:user) { create(:acl_user) }
  let(:role) { create(:role, can_view_assigned_reports: true) }

  before { setup_access_control(user, role, Collection.system_collection(:data_sources)) }

  # filter_object clamps the end date to the end of last month, so pin the clock.
  around do |example|
    travel_to(Date.parse('2026-06-15')) { example.run }
  end

  def run(klass)
    report = klass.new(user: user, filter: { filters: { start: Date.parse('2024-01-01'), end: Date.parse('2025-12-31') } })
    report.save!
    report.run_and_save!
    JSON.parse(report.precalculated_data)
  end

  it 'stores one point-in-time column per last Wednesday of January' do
    expect(run(PublicReports::PointInTime)).to eq(
      [
        ['x', '2024-01-31', '2025-01-29'],
        ['Unique people experiencing homelessness', 0, 0],
      ],
    )
  end

  it 'stores one PIT-by-month column per month after the first' do
    months = (Date.parse('2024-02-01')..Date.parse('2025-12-01')).select { |date| date.day == 1 }.map(&:iso8601)

    expect(run(PublicReports::PitByMonth)).to eq(
      [
        ['x', *months],
        ['Average people homeless per day', *Array.new(months.size, 0)],
        ['Average newly homeless per day', *Array.new(months.size, 0)],
      ],
    )
  end
end
