###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'dq_context'

RSpec.describe HudDataQualityReport::Generators::Fy2022::QuestionSix, type: :model do
  include_context 'dq context FY2022'

  before(:all) do
    default_setup
    run(default_filter, HudDataQualityReport::Generators::Fy2022::QuestionSix::QUESTION_NUMBER)
  end

  after(:all) do
    cleanup
  end

  it 'sees the starts' do
    expect(report_result.answer(question: 'Q6', cell: 'B2').summary).to eq(1)
  end

  it 'sees the exits' do
    expect(report_result.answer(question: 'Q6', cell: 'C2').summary).to eq(4)
  end
end
