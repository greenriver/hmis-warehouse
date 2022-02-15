###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'spm_context'

RSpec.describe HudSpmReport::Generators::Fy2020::MeasureFour, type: :model do
  include_context 'HudSpmReport context'

  before(:all) do
    setup('fy2020/measure_four')
    filter = ::Filters::HudFilterBase.new(
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
    ['4.1', 'A1', nil],
    ['4.1', 'C2', 2, 'system stayers'],
    ['4.1', 'C3', 1, 'w/ increased earned income'],
    ['4.1', 'C4', 50.00, '% w/ increased earned income'],

    ['4.2', 'A1', nil],
    ['4.2', 'C2', 2, 'system stayers'],
    ['4.2', 'C3', 1, 'w/ increased non-employment cash'],
    ['4.2', 'C4', 50.00, '% w/ increased income'],

    ['4.3', 'A1', nil],
    ['4.3', 'C2', 2, 'system stayers'],
    ['4.3', 'C3', 1, 'w/ increased total income'],
    ['4.3', 'C4', 50.00, '% w/ increased income'],

    ['4.4', 'A1', nil],
    ['4.4', 'C2', 2, 'system leavers'],
    ['4.4', 'C3', 1, 'w/ increased earned income'],
    ['4.4', 'C4', 50.00, '% w/ increased income'],

    ['4.5', 'A1', nil],
    ['4.5', 'C2', 2, 'system leavers'],
    ['4.5', 'C3', 1, 'w/ increased non-employment cash'],
    ['4.5', 'C4', 50.00, '% w/ increased income'],

    ['4.6', 'A1', nil],
    ['4.6', 'C2', 2, 'system leavers'],
    ['4.6', 'C3', 1, 'w/ increased total income'],
    ['4.6', 'C4', 50.00, '% w/ increased income'],
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
