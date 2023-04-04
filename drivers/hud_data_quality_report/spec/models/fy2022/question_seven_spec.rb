###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'dq_context'

RSpec.describe HudDataQualityReport::Generators::Fy2022::QuestionSeven, type: :model do
  include_context 'dq context FY2022'

  before(:all) do
    default_setup
    run(night_by_night_shelter, HudDataQualityReport::Generators::Fy2022::QuestionSeven::QUESTION_NUMBER)
  end

  after(:all) do
    cleanup
  end

  it 'sees the stayers' do
    expect(report_result.answer(question: 'Q7', cell: 'B2').summary).to eq(5)
  end

  it 'there was a contact' do
    answer = report_result.answer(question: 'Q7', cell: 'D2').summary
    expect(answer).not_to eq(nil)
    expect(answer).not_to eq('1.0000')
  end
end
