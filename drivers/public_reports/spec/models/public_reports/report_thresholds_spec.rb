###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PublicReports::Report, type: :model do
  let(:report) { PublicReports::StateDashboard.new }

  it 'zeroes location and donut percentages when the total is exactly 100 and a part is under 11' do
    expect([report.enforce_min_threshold([95, 5], 'location'), report.enforce_min_threshold([95, 5], 'donut')]).to eq([[0, 0], [0, 0]])
  end

  it 'publishes location percentages rounded to ten once the total is over 100' do
    expect(report.enforce_min_threshold([96, 5], 'location')).to eq([90, 10])
  end
end
