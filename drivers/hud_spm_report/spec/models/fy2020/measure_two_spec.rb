###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'spm_context'

RSpec.describe HudSpmReport::Generators::Fy2020::MeasureTwo, type: :model do
  include_context 'HudSpmReport context'

  before(:all) do
    setup('fy2020/measure_two')
    filter = ::Filters::HudFilterBase.new(
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
    ['A1', nil],

    ['B2', 0, 'exiting to PH from SO'],
    ['B3', 3, 'exiting to PH from ES'],
    ['B4', 0, 'exiting to PH from TH'],
    ['B5', 0, 'exiting to PH from SH'],
    ['B6', 0, 'exiting to PH from PH'],
    ['B7', 3, 'exiting to PH'],

    ['C2', 0, 'returning in <6mo from SO'],
    ['C3', 0, 'returning in <6mo from ES'],
    ['C4', 0, 'returning in <6mo from TH'],
    ['C5', 0, 'returning in <6mo from SH'],
    ['C6', 0, 'returning in <6mo from PH'],
    ['C7', 0, 'returning in <6mo'],

    ['D2', 0, '% returning in <6mo from SO'],
    ['D3', 0, '% returning in <6mo from ES'],
    ['D4', 0, '% returning in <6mo from TH'],
    ['D5', 0, '% returning in <6mo from SH'],
    ['D6', 0, '% returning in <6mo from PH'],
    ['D7', 0, '% returning in <6mo'],

    ['E2', 0, 'returning in 6-12mo from SO'],
    ['E3', 0, 'returning in 6-12mo from ES'],
    ['E4', 0, 'returning in 6-12mo from TH'],
    ['E5', 0, 'returning in 6-12mo from SH'],
    ['E6', 0, 'returning in 6-12mo from PH'],
    ['E7', 0, 'returning in 6-12mo'],

    ['F2', 0, '% returning in 6-12mo from SO'],
    ['F3', 0, '% returning in 6-12mo from ES'],
    ['F4', 0, '% returning in 6-12mo from TH'],
    ['F5', 0, '% returning in 6-12mo from SH'],
    ['F6', 0, '% returning in 6-12mo from PH'],
    ['F7', 0, '% returning in 6-12mo'],

    ['G2', 0, 'returning in 13-24mo from SO'],
    ['G3', 2, 'returning in 13-24mo from ES'],
    ['G4', 0, 'returning in 13-24mo from TH'],
    ['G5', 0, 'returning in 13-24mo from SH'],
    ['G6', 0, 'returning in 13-24mo from PH'],
    ['G7', 2, 'returning in 13-24mo'],

    ['H2', 0, '% returning in 13-24mo from SO'],
    ['H3', 66.67, '% returning in 13-24mo from ES'],
    ['H4', 0, '% returning in 13-24mo from TH'],
    ['H5', 0, '% returning in 13-24mo from SH'],
    ['H6', 0, '% returning in 13-24mo from PH'],
    ['H7', 66.67, '% returning in 13-24mo'],

    ['I2', 0, 'returning in <2yr from SO'],
    ['I3', 2, 'returning in <2yr from ES'],
    ['I4', 0, 'returning in <2yr from TH'],
    ['I5', 0, 'returning in <2yr from SH'],
    ['I6', 0, 'returning in <2yr from SO'],
    ['I7', 2, 'returning in <2yr'],

    ['J2', 0, '% returning in <2yr from SO'],
    ['J3', 66.67, '% returning in <2yr from ES'],
    ['J4', 0, '% returning in <2yr from TH'],
    ['J5', 0, '% returning in <2yr from SH'],
    ['J6', 0, '% returning in <2yr from SO'],
    ['J7', 66.67, '% returning in <2yr'],
  ].each do |cell, expected_value, label|
    question = '2'
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
