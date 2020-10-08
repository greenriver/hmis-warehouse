require 'rails_helper'
require_relative 'apr_context'

RSpec.describe HudApr::Generators::Apr::Fy2020::QuestionEight, type: :model do
  include_context 'apr context'

  before(:all) do
    default_setup
    run(default_filter, HudApr::Generators::Apr::Fy2020::QuestionEight::QUESTION_NUMBER)
  end

  after(:all) do
    cleanup
  end

  describe 'Q8a: Number of Households Served' do
    it 'counts households' do
      expect(report_result.answer(question: 'Q8a', cell: 'B2').summary).to eq(8)
    end

    it 'counts households without children' do
      expect(report_result.answer(question: 'Q8a', cell: 'C2').summary).to eq(5)
    end

    it 'counts households with children and adults' do
      expect(report_result.answer(question: 'Q8a', cell: 'D2').summary).to eq(1)
    end

    it 'counts households with only children' do
      expect(report_result.answer(question: 'Q8a', cell: 'E2').summary).to eq(1)
    end

    it 'counts unknown households' do
      expect(report_result.answer(question: 'Q8a', cell: 'E2').summary).to eq(1)
    end
  end

  describe 'Q8b: Point-in-Time Count of Households on the Last Wednesday' do
    it 'counts households in January' do
      expect(report_result.answer(question: 'Q8b', cell: 'B2').summary).to eq(8)
    end

    it 'counts households in April' do
      expect(report_result.answer(question: 'Q8b', cell: 'B3').summary).to eq(8)
    end

    it 'counts households in July' do
      expect(report_result.answer(question: 'Q8b', cell: 'B4').summary).to eq(5)
    end

    it 'counts households in Oct' do
      expect(report_result.answer(question: 'Q8b', cell: 'B5').summary).to eq(5)
    end
  end
end
