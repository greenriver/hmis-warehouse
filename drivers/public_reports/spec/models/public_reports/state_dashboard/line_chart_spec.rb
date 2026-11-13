###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PublicReports::StateDashboard::LineChart do
  subject(:chart) { described_class.new(labels: ['2024'], series: [{ 'label' => 'People', 'values' => [100] }]) }

  describe '#format_value' do
    it 'labels the suppressed value as 100 or fewer and shows other values as delimited numbers' do
      expect([0, 99, 100, 101, 12_345].map { |value| chart.format_value(value) }).to eq(['0', '99', '100 or fewer', '101', '12,345'])
    end
  end
end
