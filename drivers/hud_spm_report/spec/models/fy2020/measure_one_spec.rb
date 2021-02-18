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
    GrdaWarehouse::Utility.clear!
    setup('fy2020/measure_one')

    # puts described_class.question_number
    run(default_filter, described_class.question_number)
  end

  after(:all) do
    # Because we are only running the import once, we have to do our own DB and file cleanup
    GrdaWarehouse::Utility.clear!
    cleanup_files
    Delayed::Job.delete_all
  end

  it 'has been provided client data' do
    assert_equal 1, @data_source.clients.count
  end

  it 'completed successfully' do
    assert_equal 'Completed', report_result.state
    assert_equal [described_class.question_number], report_result.build_for_questions
    assert report_result.remaining_questions.none?
  end

  M1AE2_DAYS =  151
  M1BE2_DAYS =  397

  [
    ['1a', 'A1', nil],
    ['1a', 'C2', 1, 'persons in ES and SH'],
    ['1a', 'E2', M1AE2_DAYS, 'mean LOT in ES and SH'],
    ['1a', 'H2', M1AE2_DAYS, 'median LOT in ES and SH'],

    # ['1a', 'C3', 1, 'persons in ES, SH, and TH'],
    # ['1a', 'E3', 0, 'mean LOT in ES, SH, and TH'],
    # ['1a', 'H3', 0, 'median LOT in ES, SH, and TH'],

    ['1b', 'A1', nil],
    ['1b', 'C2', 1, 'persons in ES, SH, and PH'],
    ['1b', 'E2', M1BE2_DAYS, 'mean LOT in ES, SH, and PH'],
    ['1b', 'H2', M1BE2_DAYS, 'median LOT in ES, SH, and PH'],

    # ['1b', 'C3', 1, 'persons in ES, SH, TH, and PH'],
    # ['1b', 'E3', 0, 'mean LOT in ES, SH, TH, and PH'],
    # ['1b', 'H3', 0, 'median LOT in ES, SH, TH, and PH'],
    # ['1b', 'I3', 0],
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
