###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'dq_context'

RSpec.describe HudDataQualityReport::Generators::Fy2022::QuestionTwo, type: :model do
  include_context 'dq context FY2022'

  before(:all) do
    default_setup
    run(default_filter, HudDataQualityReport::Generators::Fy2022::QuestionTwo::QUESTION_NUMBER)
  end

  after(:all) do
    cleanup
  end

  it 'finds no SSN issues' do
    expect(report_result.answer(question: 'Q2', cell: 'E3').summary).to eq(0)
  end
  it 'finds the missing DOB' do
    expect(report_result.answer(question: 'Q2', cell: 'C4').summary).to eq(1)
  end
  it 'finds the DK/R races' do
    expect(report_result.answer(question: 'Q2', cell: 'B5').summary).to eq(2)
  end
  it 'finds three total Race flags' do
    expect(report_result.answer(question: 'Q2', cell: 'E5').summary).to eq(3)
  end
  it 'finds four clients with issues' do
    expect(report_result.answer(question: 'Q2', cell: 'E8').summary).to eq(4)
  end
end
