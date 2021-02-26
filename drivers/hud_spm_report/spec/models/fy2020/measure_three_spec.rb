###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'spm_context'

RSpec.describe HudSpmReport::Generators::Fy2020::MeasureThree, type: :model do
  include_context 'HudSpmReport context'

  before(:all) do
    setup('fy2020/measure_three')
    filter = HudSpmReport::Filters::SpmFilter.new(
      shared_filter.merge(
        start: Date.parse('2015-1-1'),
        end: Date.parse('2015-12-31'),
      ),
    )
    run(filter, described_class.question_number)
  end

  it 'has been provided client data' do
    assert_equal 6, @data_source.clients.count
  end

  it 'completed successfully' do
    assert_report_completed
  end

  [
    ['3.1', 'A1', nil],
    ['3.1', 'C2', nil], # instructions tell us to leave blank for a human to fill in
    ['3.1', 'C3', nil],
    ['3.1', 'C4', nil],
    ['3.1', 'C5', nil],
    ['3.1', 'C6', nil],
    ['3.1', 'C7', nil],

    ['3.2', 'A1', nil],
    ['3.2', 'C2', 3, 'unduplicated total sheltered homeless persons'],
    ['3.2', 'C3', 1, 'emergency shelter'],
    ['3.2', 'C4', 1, 'safe haven'],
    ['3.2', 'C5', 1, 'transitional housing'],
  ].each do |question, cell, expected_value, label|
    test_name = if expected_value.nil?
      "does not fill #{question} #{cell} #{label}".strip
    else
      "fills #{question} #{cell} (#{label}) with #{expected_value}"
    end
    it test_name do
      expect(report_result.answer(question: question, cell: cell).summary).to eq(expected_value)
    end
  end
end
