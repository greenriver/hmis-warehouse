require 'rails_helper'
require_relative 'dq_context'

RSpec.describe HudDataQualityReport::Generators::Fy2020::QuestionFour, type: :model do
  include_context 'dq context'

  before(:all) do
    default_setup
    run(default_filter, HudDataQualityReport::Generators::Fy2020::QuestionFour::QUESTION_NUMBER)
  end

  after(:all) do
    cleanup
  end

  it 'counts at least one income' do
    answer = report_result.answer(question: 'Q4', cell: 'C3').summary
    expect(answer).not_to eq(nil)
    expect(answer).not_to eq('1.0000')
  end
end
