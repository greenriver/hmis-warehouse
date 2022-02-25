###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'dq_context'

RSpec.describe HudDataQualityReport::Generators::Fy2022::QuestionThree, type: :model do
  include_context 'dq context FY2022'

  before(:all) do
    default_setup
    run(default_filter, HudDataQualityReport::Generators::Fy2022::QuestionThree::QUESTION_NUMBER)
  end

  after(:all) do
    cleanup
  end

  it 'hoh denominator is correct' do
    expect(report_result.answer(question: 'Q3', cell: 'C5').summary).to eq('0.0000')
  end
end
