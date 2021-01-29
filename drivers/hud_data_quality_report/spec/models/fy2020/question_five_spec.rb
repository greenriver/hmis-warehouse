###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'dq_context'

RSpec.describe HudDataQualityReport::Generators::Fy2020::QuestionFive, type: :model do
  include_context 'dq context'

  before(:all) do
    default_setup
    run(default_filter, HudDataQualityReport::Generators::Fy2020::QuestionFive::QUESTION_NUMBER)
  end

  after(:all) do
    cleanup
  end

  it 'counts adults and hoh' do
    expect(report_result.answer(question: 'Q5', cell: 'B5').summary).to eq(8)
  end

  it 'counts at least one invalid record' do
    answer = report_result.answer(question: 'Q5', cell: 'H5').summary
    expect(answer).not_to eq(nil)
    expect(answer).not_to eq('1.0000')
  end
end
