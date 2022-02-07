###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'path_context'

RSpec.describe HudPathReport::Generators::Fy2020::QuestionEighteen, type: :model do
  include_context 'path context'

  before(:all) do
    default_setup
    run(default_filter, HudPathReport::Generators::Fy2020::QuestionEighteen::QUESTION_NUMBER)
  end

  after(:all) do
    cleanup
  end

  it 'counts community mental health referrals' do
    expect(report_result.answer(question: 'Q18', cell: 'B2').summary).to eq(2)
  end

  it 'counts community mental health referrals successes' do
    expect(report_result.answer(question: 'Q18', cell: 'C2').summary).to eq(1)
  end
end
