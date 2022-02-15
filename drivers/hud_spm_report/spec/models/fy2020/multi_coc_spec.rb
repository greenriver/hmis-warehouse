###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'spm_context'

RSpec.describe HudSpmReport::Generators::Fy2020::MeasureSix, type: :model do
  include_context 'HudSpmReport context'

  before(:all) do
    setup('fy2020/multi_coc')
    filter = ::Filters::HudFilterBase.new(
      shared_filter.merge(
        start: Date.parse('2015-1-1'),
        end: Date.parse('2015-12-31'),
      ),
    )
    run(filter, described_class.question_number)
  end

  it 'has been provided client data' do
    assert_equal 7, @data_source.clients.count
  end

  it 'completed successfully' do
    assert_report_completed
  end

  [
    ['6a.1 and 6b.1', 'A1', nil],

    ['6a.1 and 6b.1', 'B2', nil, 'exiting to PH from SO'],
    ['6a.1 and 6b.1', 'B3', nil, 'exiting to PH from ES'],
    ['6a.1 and 6b.1', 'B4', 0, 'exiting to PH from TH'],
    ['6a.1 and 6b.1', 'B5', 3, 'exiting to PH from SH'],
    ['6a.1 and 6b.1', 'B6', 0, 'exiting to PH from PH'],
    ['6a.1 and 6b.1', 'B7', 3, 'exiting to PH'],

    ['6a.1 and 6b.1', 'C2', nil, 'returning in <6mo from SO'],
    ['6a.1 and 6b.1', 'C3', nil, 'returning in <6mo from ES'],
    ['6a.1 and 6b.1', 'C4', 0, 'returning in <6mo from TH'],
    ['6a.1 and 6b.1', 'C5', 0, 'returning in <6mo from SH'],
    ['6a.1 and 6b.1', 'C6', 0, 'returning in <6mo from PH'],
    ['6a.1 and 6b.1', 'C7', 0, 'returning in <6mo'],

    ['6a.1 and 6b.1', 'D2', nil, '% returning in <6mo from SO'],
    ['6a.1 and 6b.1', 'D3', nil, '% returning in <6mo from ES'],
    ['6a.1 and 6b.1', 'D4', 0, '% returning in <6mo from TH'],
    ['6a.1 and 6b.1', 'D5', 0, '% returning in <6mo from SH'],
    ['6a.1 and 6b.1', 'D6', 0, '% returning in <6mo from PH'],
    ['6a.1 and 6b.1', 'D7', 0, '% returning in <6mo'],

    ['6a.1 and 6b.1', 'E2', nil, 'returning in 6-12mo from SO'],
    ['6a.1 and 6b.1', 'E3', nil, 'returning in 6-12mo from ES'],
    ['6a.1 and 6b.1', 'E4', 0, 'returning in 6-12mo from TH'],
    ['6a.1 and 6b.1', 'E5', 0, 'returning in 6-12mo from SH'],
    ['6a.1 and 6b.1', 'E6', 0, 'returning in 6-12mo from PH'],
    ['6a.1 and 6b.1', 'E7', 0, 'returning in 6-12mo'],

    ['6a.1 and 6b.1', 'F2', nil, '% returning in 6-12mo from SO'],
    ['6a.1 and 6b.1', 'F3', nil, '% returning in 6-12mo from ES'],
    ['6a.1 and 6b.1', 'F4', 0, '% returning in 6-12mo from TH'],
    ['6a.1 and 6b.1', 'F5', 0, '% returning in 6-12mo from SH'],
    ['6a.1 and 6b.1', 'F6', 0, '% returning in 6-12mo from PH'],
    ['6a.1 and 6b.1', 'F7', 0, '% returning in 6-12mo'],

    ['6a.1 and 6b.1', 'G2', nil, 'returning in 13-24mo from SO'],
    ['6a.1 and 6b.1', 'G3', nil, 'returning in 13-24mo from ES'],
    ['6a.1 and 6b.1', 'G4', 0, 'returning in 13-24mo from TH'],
    ['6a.1 and 6b.1', 'G5', 2, 'returning in 13-24mo from SH'],
    ['6a.1 and 6b.1', 'G6', 0, 'returning in 13-24mo from PH'],
    ['6a.1 and 6b.1', 'G7', 2, 'returning in 13-24mo'],

    ['6a.1 and 6b.1', 'H2', nil, '% returning in 13-24mo from SO'],
    ['6a.1 and 6b.1', 'H3', nil, '% returning in 13-24mo from ES'],
    ['6a.1 and 6b.1', 'H4', 0, '% returning in 13-24mo from TH'],
    ['6a.1 and 6b.1', 'H5', 66.67, '% returning in 13-24mo from SH'],
    ['6a.1 and 6b.1', 'H6', 0, '% returning in 13-24mo from PH'],
    ['6a.1 and 6b.1', 'H7', 66.67, '% returning in 13-24mo'],

    ['6a.1 and 6b.1', 'I2', nil, 'returning in <2yr from SO'],
    ['6a.1 and 6b.1', 'I3', nil, 'returning in <2yr from ES'],
    ['6a.1 and 6b.1', 'I4', 0, 'returning in <2yr from TH'],
    ['6a.1 and 6b.1', 'I5', 2, 'returning in <2yr from SH'],
    ['6a.1 and 6b.1', 'I6', 0, 'returning in <2yr from SO'],
    ['6a.1 and 6b.1', 'I7', 2, 'returning in <2yr'],

    ['6a.1 and 6b.1', 'J2', nil, '% returning in <2yr from SO'],
    ['6a.1 and 6b.1', 'J3', nil, '% returning in <2yr from ES'],
    ['6a.1 and 6b.1', 'J4', 0, '% returning in <2yr from TH'],
    ['6a.1 and 6b.1', 'J5', 66.67, '% returning in <2yr from SH'],
    ['6a.1 and 6b.1', 'J6', 0, '% returning in <2yr from SO'],
    ['6a.1 and 6b.1', 'J7', 66.67, '% returning in <2yr'],

    ['6c.1', 'C2', 5, 'Cat. 3 Persons in SH, TH and PH-RRH who exited, plus persons in other PH projects who exited without moving into housing'],
    ['6c.1', 'C3', 1, 'with the desired final state'],
    ['6c.1', 'C4', 20, '.. as percentage'],

    ['6c.2', 'C2', 1, 'Cat. 3 Persons in all PH projects except PH-RRH who exited after moving into housing, or who moved into housing and remained in the PH project'],
    ['6c.2', 'C3', 0, 'with the desired final state'],
    ['6c.2', 'C4', 0, '.. as percentage'],
  ].each do |table, cell, expected_value, label|
    test_name = if expected_value.nil?
      "does not fill #{table} #{cell} #{label}".strip
    else
      "fills #{table} #{cell} (#{label}) with #{expected_value}"
    end
    it test_name do
      expect(report_result.answer(question: table, cell: cell).summary).to eq(expected_value)
    end
  end
end
