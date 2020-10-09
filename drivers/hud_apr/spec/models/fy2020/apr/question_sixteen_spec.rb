require 'rails_helper'
require_relative 'apr_context'

RSpec.describe HudApr::Generators::Apr::Fy2020::QuestionSixteen, type: :model do
  include_context 'apr context'

  before(:all) do
    default_setup
    run(default_filter, HudApr::Generators::Apr::Fy2020::QuestionSixteen::QUESTION_NUMBER)
  end

  after(:all) do
    cleanup
  end

  describe 'Q16: Cash Income - Ranges' do
    it 'counts entries' do
      expect(report_result.answer(question: 'Q16', cell: 'B2').summary).to eq(1)
      expect(report_result.answer(question: 'Q16', cell: 'B11').summary).to eq(5)
      expect(report_result.answer(question: 'Q16', cell: 'B14').summary).to eq(6)
    end

    it 'counts annual assessments' do
      expect(report_result.answer(question: 'Q16', cell: 'C12').summary).to eq(1)
      expect(report_result.answer(question: 'Q16', cell: 'C13').summary).to eq(2)
    end
  end
end
