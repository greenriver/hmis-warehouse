###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'spm_context'

RSpec.describe HudSpmReport::Generators::Fy2020::MeasureSeven, type: :model do
  include_context 'HudSpmReport context'

  before(:all) do
    setup('fy2020/measure_seven')
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
    ['7a.1', 'A1', nil],
    ['7a.1', 'C2', 0],
    ['7a.1', 'C3', 0],
    ['7a.1', 'C4', 0],
    ['7a.1', 'C5', 0],
    ['7b.1', 'C2', 0],
    ['7b.1', 'C3', 0],
    ['7b.1', 'C4', 0],
    ['7b.2', 'C2', 0],
    ['7b.2', 'C3', 0],
    ['7b.2', 'C4', 0],
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
