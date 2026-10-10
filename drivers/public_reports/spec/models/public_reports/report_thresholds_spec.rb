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
    def buckets(sizes)
      next_id = 0
      sizes.transform_values do |size|
        Set.new((next_id + 1)..(next_id += size))
      end
    end

    def collapse(sizes)
      report.enforce_min_threshold(buckets(sizes), 'race').transform_values(&:size)
    end

    it 'treats a bucket of exactly 100 as too small to publish' do
      expect(collapse('White' => 150, 'Black' => 101, 'Asian' => 100)).to eq('White' => 150, 'Black' => 0, 'Asian' => 0, 'None' => 201)
    end

    it 'merges the smallest remaining bucket into "None" when "None" would publish 100 or fewer' do
      expect(collapse('White' => 150, 'Black' => 120, 'Asian' => 50, 'Pacific' => 50)).to eq('White' => 150, 'Black' => 0, 'Asian' => 0, 'Pacific' => 0, 'None' => 220)
    end

    it 'leaves "None" alone once it holds more than 100' do
      expect(collapse('White' => 150, 'Black' => 101, 'Asian' => 5, 'None' => 96)).to eq('White' => 150, 'Black' => 101, 'Asian' => 0, 'None' => 101)
    end

    it 'publishes an empty "None" bucket without merging anything into it' do
      expect(collapse('White' => 150, 'Black' => 120)).to eq('White' => 150, 'Black' => 120, 'None' => 0)
    end

    it 'puts every bucket into "None" when none holds more than 100' do
      expect(collapse('White' => 50, 'Asian' => 5)).to eq('White' => 0, 'Asian' => 0, 'None' => 55)
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
