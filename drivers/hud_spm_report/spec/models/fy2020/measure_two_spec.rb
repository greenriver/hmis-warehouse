###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'spm_context'

RSpec.describe HudSpmReport::Generators::Fy2020::MeasureTwo, type: :model do
  include_context 'HudSpmReport context'

  before(:all) do
    setup('fy2020/measure_two')
    filter = HudSpmReport::Filters::SpmFilter.new(
      shared_filter.merge(
        start: Date.parse('2015-1-1'),
        end: Date.parse('2015-12-31'),
      ),
    )
    run(filter, described_class.question_number)
  end

  it 'has been provided client data' do
    assert_equal 4, @data_source.clients.count
  end

  it 'completed successfully' do
    assert_report_completed
  end

  [
    ['2', 'A1', nil],
    ['2', 'B7', 3, 'clients exiting to PH'],
    ['2', 'G6', 0, 'clients returning to homelessness from PH'],
    ['2', 'G4', 0, 'returning to homelessness from TH'],
    # ['2', 'G3', 2, 'returning to homelessness from ES'],
    ['2', 'C3', 0, 'returning to homelessness from ES between 6 months and a year'],
    # ['2', 'I7', 2, 'clients returning to homelessness'],
    ['2', 'C7', 0, 'returning to homelessness in less than 6 months'],
    ['2', 'E7', 0, 'returning to homelessness in 6-12 months'],
    # ['2', 'G7', 2, 'returning to homelessness in 13-24 months'],
  ].each do |question, cell, expected_value, label|
    test_name = if expected_value.nil?
      "does not fill #{question} #{cell}"
    else
      "fills #{question} #{cell} (#{label}) with #{expected_value}"
    end
    it test_name do
      expect(report_result.answer(question: question, cell: cell).summary).to eq(expected_value)
    end
  end
end
