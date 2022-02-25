###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'path_context'

RSpec.describe HudPathReport::Generators::Fy2021::QuestionEighteen, type: :model do
  include_context 'path context FY2021'

  before(:all) do
    default_setup
    run(default_filter, HudPathReport::Generators::Fy2021::QuestionEighteen::QUESTION_NUMBER)
  end

  after(:all) do
    cleanup
  end

  it 'counts substance use referrals' do
    expect(report_result.answer(question: 'Q18', cell: 'B3').summary).to eq(2)
  end

  it 'counts substance referrals successes' do
    expect(report_result.answer(question: 'Q18', cell: 'C3').summary).to eq(1)
  end
end
