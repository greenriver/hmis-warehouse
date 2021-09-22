###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'apr_context'

RSpec.describe HudApr::Generators::Apr::Fy2021::QuestionTwentyOne, type: :model do
  include_context 'apr context FY2021'

  before(:all) do
    default_setup
    run(default_filter, HudApr::Generators::Apr::Fy2021::QuestionTwentyOne::QUESTION_NUMBER)
  end

  after(:all) do
    cleanup
  end

  describe 'Q21: Health Insurance' do
    it 'finds no insurance at start' do
      expect(report_result.answer(question: 'Q21', cell: 'B12').summary).to eq(1)
    end
    it 'finds medicaid at start' do
      expect(report_result.answer(question: 'Q21', cell: 'B2').summary).to eq(1)
    end
    it 'finds medicaid at annual assessment' do
      expect(report_result.answer(question: 'Q21', cell: 'C2').summary).to eq(1)
    end
    it 'finds medicaid at exit' do
      expect(report_result.answer(question: 'Q21', cell: 'D2').summary).to eq(1)
    end
    it 'finds stayer without annual assessment yet' do
      expect(report_result.answer(question: 'Q21', cell: 'C15').summary).to eq(1)
    end
  end
end
