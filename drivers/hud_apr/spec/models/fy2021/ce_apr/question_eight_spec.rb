###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'ce_apr_context'

RSpec.describe HudApr::Generators::CeApr::Fy2021::QuestionEight, type: :model do
  include_context 'ce apr context FY2021'

  def question_8_setup_apr_path
    'drivers/hud_apr/spec/fixtures/files/fy2021/question_8'
  end

  def question_8_setup_ce_apr_path
    'drivers/hud_apr/spec/fixtures/files/fy2021/question_8_ce_apr'
  end

  describe 'with no assessments' do
    before(:all) do
      default_setup(question_8_setup_apr_path)
      run(ph, HudApr::Generators::CeApr::Fy2021::QuestionEight::QUESTION_NUMBER)
    end

    after(:all) do
      cleanup
    end

    describe 'Q8a: Number of Households Served' do
      it 'counts households' do
        expect(report_result.answer(question: 'Q8a', cell: 'B2').summary).to eq(0)
      end

      it 'counts households without children' do
        expect(report_result.answer(question: 'Q8a', cell: 'C2').summary).to eq(0)
      end

      it 'counts households with children and adults' do
        expect(report_result.answer(question: 'Q8a', cell: 'D2').summary).to eq(0)
      end

      it 'counts households with only children' do
        expect(report_result.answer(question: 'Q8a', cell: 'E2').summary).to eq(0)
      end

      it 'counts unknown households' do
        expect(report_result.answer(question: 'Q8a', cell: 'E2').summary).to eq(0)
      end
    end
  end

  describe 'with assessments' do
    before(:all) do
      default_setup(question_8_setup_ce_apr_path)
      run(ph, HudApr::Generators::CeApr::Fy2021::QuestionEight::QUESTION_NUMBER)
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
  end
end
