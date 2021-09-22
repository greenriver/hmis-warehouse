###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'apr_context'

RSpec.describe HudApr::Generators::Apr::Fy2021::QuestionSixteen, type: :model do
  include_context 'apr context'

  before(:all) do
    default_setup
    run(default_filter, HudApr::Generators::Apr::Fy2021::QuestionSixteen::QUESTION_NUMBER)
  end

  after(:all) do
    cleanup
  end

  describe 'Q16: Cash Income - Ranges' do
    it 'counts entries' do
      expect(report_result.answer(question: 'Q16', cell: 'B2').summary).to eq(1)
      expect(report_result.answer(question: 'Q16', cell: 'B3').summary).to eq(1)
      expect(report_result.answer(question: 'Q16', cell: 'B11').summary).to eq(4)
      expect(report_result.answer(question: 'Q16', cell: 'B14').summary).to eq(6)
    end

    it 'counts annual assessments' do
      expect(report_result.answer(question: 'Q16', cell: 'C12').summary).to eq(1)
      expect(report_result.answer(question: 'Q16', cell: 'C13').summary).to eq(1)
    end

    it 'counts amounts in annual assessments' do
      expect(report_result.answer(question: 'Q16', cell: 'C3').summary).to eq(1)
    end
  end
end
