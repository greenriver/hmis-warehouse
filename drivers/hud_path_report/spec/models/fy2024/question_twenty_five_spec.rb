###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'path_context'

RSpec.describe HudPathReport::Generators::Fy2024::QuestionTwentyFive, type: :model do
  include_context 'path context FY2024'

  before(:all) do
    default_setup
    run(default_filter, HudPathReport::Generators::Fy2024::QuestionTwentyFive::QUESTION_NUMBER)
  end

  after(:all) do
    cleanup
  end

  it 'counts exits foster care' do
    expect(report_result.answer(question: 'Q25', cell: 'B8').summary).to eq(1)
  end

  it 'sums the institutional destinations' do
    expect(report_result.answer(question: 'Q25', cell: 'B14').summary).to eq(1)
  end

  it 'other subtotals are zero' do
    [23, 32].each do |row|
      expect(report_result.answer(question: 'Q25', cell: 'B' + row.to_s).summary).to eq(0)
    end
  end

  it 'counts stayers' do
    expect(report_result.answer(question: 'Q25', cell: 'B41').summary).to eq(1)
  end

  it 'counts total' do
    expect(report_result.answer(question: 'Q25', cell: 'B42').summary).to eq(2)
  end
end
