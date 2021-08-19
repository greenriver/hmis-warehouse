###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'spm_context'

RSpec.describe HudSpmReport::Generators::Fy2020::MeasureFive, type: :model do
  include_context 'HudSpmReport context'

  before(:all) do
    setup('fy2020/measure_five')
    filter = ::Filters::HudFilterBase.new(
      shared_filter.merge(
        start: Date.parse('2015-1-1'),
        end: Date.parse('2015-12-31'),
      ),
    )
    run(filter, described_class.question_number)
  end

  it 'has been provided client data' do
    assert_equal 8, @data_source.clients.count
  end

  it 'completed successfully' do
    assert_report_completed
  end

  [
    ['5.1', 'A1', nil],
    ['5.1', 'C2', 6, 'person with entries into ES, SH, or TH'], # instructions tell us to leave blank for a human to fill in
    ['5.1', 'C3', 3, 'w/ prior enrollment in the last 24m'],
    ['5.1', 'C4', 3, 'w/o - aka first time homeless'],

    ['5.2', 'A1', nil],
    ['5.2', 'C2', 8, 'person with entries into ES, SH, or TH'], # instructions tell us to leave blank for a human to fill in
    ['5.2', 'C3', 4, 'w/ prior enrollment in the last 24m'],
    ['5.2', 'C4', 4, 'w/o - aka first time homeless'],
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
