require 'rails_helper'
require_relative 'apr_context'

RSpec.describe HudApr::Generators::Apr::Fy2020::QuestionFour, type: :model do
  include_context 'apr context'

  before(:all) do
    default_setup
    run(default_filter, HudApr::Generators::Apr::Fy2020::QuestionFour::QUESTION_NUMBER)
  end

  after(:all) do
    cleanup
  end

  it 'runs' do
    expect(report_result.answer(question: 'Q4a', cell: 'A2').summary).to eq('Test Organization')
  end

  def report_result
    ::HudReports::ReportInstance.last
  end
end
