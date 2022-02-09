###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'apr_context'

RSpec.describe HudApr::Generators::Apr::Fy2021::QuestionFifteen, type: :model do
  include_context 'apr context FY2021'

  before(:all) do
    default_setup
    run(default_filter, HudApr::Generators::Apr::Fy2021::QuestionFifteen::QUESTION_NUMBER)
  end

  after(:all) do
    cleanup
  end

  describe 'Q15: Living Situation' do
    it 'handles null prior living situations' do
      expect(report_result.answer(question: 'Q15', cell: 'B35').summary).to eq(8)
      expect(report_result.answer(question: 'Q15', cell: 'C35').summary).to eq(5)
      expect(report_result.answer(question: 'Q15', cell: 'D35').summary).to eq(1)
      expect(report_result.answer(question: 'Q15', cell: 'E35').summary).to eq(1)
      expect(report_result.answer(question: 'Q15', cell: 'F35').summary).to eq(1)
    end
  end
end
