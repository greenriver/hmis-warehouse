require 'rails_helper'
require_relative 'caper_context'

RSpec.describe HudApr::Generators::Caper::Fy2020::QuestionTwentyFour, type: :model do
  include_context 'caper context'

  before(:all) do
    default_setup
    run(default_filter, HudApr::Generators::Caper::Fy2020::QuestionTwentyFour::QUESTION_NUMBER)
  end

  after(:all) do
    cleanup
  end
  describe 'Q24: Homelessness Prevention Housing Assessment at Exit' do
    it 'counts exits' do
      expect(report_result.answer(question: 'Q24', cell: 'B4').summary).to eq(2)
      expect(report_result.answer(question: 'Q24', cell: 'B9').summary).to eq(1)
      expect(report_result.answer(question: 'Q24', cell: 'B15').summary).to eq(1)
      expect(report_result.answer(question: 'Q24', cell: 'B16').summary).to eq(4)
    end
  end
end
