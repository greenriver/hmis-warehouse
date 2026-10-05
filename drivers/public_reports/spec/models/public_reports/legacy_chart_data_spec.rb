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

  def run(klass)
    report = klass.new(user: user, filter: { filters: { start: Date.parse('2024-01-01'), end: Date.parse('2025-12-31') } })
    report.save!(validate: false)
    report.run_and_save!
    JSON.parse(report.precalculated_data)
  end

  it 'stores point-in-time counts as billboard.js columns' do
    expect(run(PublicReports::PointInTime).map(&:first)).to eq(['x', 'Unique people experiencing homelessness'])
  end

  it 'stores PIT-by-month counts as billboard.js columns' do
    expect(run(PublicReports::PitByMonth).map(&:first)).to eq(['x', 'Average people homeless per day', 'Average newly homeless per day'])
  end
end
