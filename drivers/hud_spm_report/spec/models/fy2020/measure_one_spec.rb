###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'spm_context'

RSpec.describe HudSpmReport::Generators::Fy2020::MeasureOne, type: :model do
  include_context 'HudSpmReport context'

  before(:all) do
    # puts described_class.question_number
    run(default_filter, described_class.question_number)
  end

  it 'parses' do
    assert true, 'code loads OK'
  end

  it 'completes successfully' do
    assert_equal 'Completed', report_result.state
    assert report_result.remaining_questions.none?
  end

  [
    ['1a', 'A1', nil],
    ['1a', 'B2', 0],
    ['1a', 'C2', 0],
    ['1a', 'D2', 0],
    ['1a', 'E2', 0],
    ['1a', 'F2', 0],
    ['1a', 'G2', 0],
    ['1a', 'H2', 0],
    ['1a', 'I2', 0],
    ['1a', 'B3', 0],
    ['1a', 'C3', 0],
    ['1a', 'D3', 0],
    ['1a', 'E3', 0],
    ['1a', 'F3', 0],
    ['1a', 'G3', 0],
    ['1a', 'H3', 0],
    ['1a', 'I3', 0],
    ['1b', 'A1', nil],
    ['1b', 'B2', 0],
    ['1b', 'C2', 0],
    ['1b', 'D2', 0],
    ['1b', 'E2', 0],
    ['1b', 'F2', 0],
    ['1b', 'G2', 0],
    ['1b', 'H2', 0],
    ['1b', 'I2', 0],
    ['1b', 'B3', 0],
    ['1b', 'C3', 0],
    ['1b', 'D3', 0],
    ['1b', 'E3', 0],
    ['1b', 'F3', 0],
    ['1b', 'G3', 0],
    ['1b', 'H3', 0],
    ['1b', 'I3', 0],
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
