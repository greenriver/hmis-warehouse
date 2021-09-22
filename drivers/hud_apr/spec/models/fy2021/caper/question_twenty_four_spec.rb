###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'caper_context'

RSpec.describe HudApr::Generators::Caper::Fy2021::QuestionTwentyFour, type: :model do
  include_context 'caper context FY2021'

  before(:all) do
    default_setup
    run(default_filter, HudApr::Generators::Caper::Fy2021::QuestionTwentyFour::QUESTION_NUMBER)
  end

  after(:all) do
    cleanup
  end
  describe 'Q24: Homelessness Prevention Housing Assessment at Exit' do
    it 'counts exits in prevention projects' do
      # FIXME There are no prevention projects in the fixture
      expect(report_result.answer(question: 'Q24', cell: 'B4').summary).to eq(0)
      expect(report_result.answer(question: 'Q24', cell: 'B9').summary).to eq(0)
      expect(report_result.answer(question: 'Q24', cell: 'B15').summary).to eq(0)
      expect(report_result.answer(question: 'Q24', cell: 'B16').summary).to eq(0)
    end
  end
end
