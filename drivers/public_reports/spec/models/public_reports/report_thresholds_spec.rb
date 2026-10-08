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

  it 'reads the part floor for location and donut percentages from MIN_THRESHOLD' do
    stub_const('PublicReports::StateDashboard::MIN_THRESHOLD', 5)

    expect([report.enforce_min_threshold([95, 5], 'location'), report.enforce_min_threshold([95, 5], 'donut')]).to eq([[90, 10], [90, 10]])
  end

  describe 'race buckets' do
    it 'moves buckets under 100 into "None" and keeps "None" even when it ends up under 100' do
      data = { 'White' => Set.new(1..150), 'Asian' => Set.new(151..155), 'None' => Set.new([156]) }

      expect(report.enforce_min_threshold(data, 'race').transform_values(&:size)).to eq('White' => 150, 'Asian' => 0, 'None' => 6)
    end

    it 'creates the "None" bucket when the data has none' do
      data = { 'White' => Set.new(1..150), 'Asian' => Set.new(151..155) }

      expect(report.enforce_min_threshold(data, 'race').transform_values(&:size)).to eq('White' => 150, 'Asian' => 0, 'None' => 5)
    end
  end

  describe 'unsheltered percent tile' do
    def tile(total, unsheltered)
      report.enforce_min_threshold({ 'homeless_clients' => total, 'unsheltered_clients' => unsheltered }, 'unsheltered_percent')
    end

    it 'is not reported when the total is at or under 100 and a part is under 11' do
      expect([tile(5, 1), tile(100, 10), tile(100, 90), tile(5, 0)]).to eq(['Not reported'] * 4)
    end

    it 'publishes a ten-rounded percent at a total of 100 when both parts are at least 11' do
      expect(tile(100, 11)).to eq('10%')
    end

    it 'publishes once the total is over 100, whatever the part sizes' do
      expect(tile(101, 1)).to eq('0%')
    end

    it 'publishes an unrounded percent when both counts are over 100' do
      expect(tile(400, 150)).to eq('38%')
    end

    it 'shows 0% when no one is homeless' do
      expect(tile(0, 0)).to eq('0%')
    end
  end
end
