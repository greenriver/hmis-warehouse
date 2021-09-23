###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'ce_apr_context'

RSpec.describe HudApr::Generators::CeApr::Fy2021::QuestionSix, type: :model do
  include_context 'ce apr context FY2021'

  describe 'with no assessments' do
    before(:all) do
      default_setup(default_setup_path)
    end

    after(:all) do
      cleanup
    end

    describe 'With default project' do
      before(:all) do
        run(default_filter, HudApr::Generators::CeApr::Fy2021::QuestionSix::QUESTION_NUMBER)
      end

      describe 'Q6a: Personally Identifiable Information' do
        it 'finds no SSN issues' do
          expect(report_result.answer(question: 'Q6a', cell: 'E3').summary).to eq(0)
        end
        it 'finds the missing DOB' do
          expect(report_result.answer(question: 'Q6a', cell: 'C4').summary).to eq(0)
        end
        it 'finds the DK/R races' do
          expect(report_result.answer(question: 'Q6a', cell: 'B5').summary).to eq(0)
        end
        it 'finds three total Race flags' do
          expect(report_result.answer(question: 'Q6a', cell: 'E5').summary).to eq(0)
        end
        it 'finds four clients with issues' do
          expect(report_result.answer(question: 'Q6a', cell: 'E8').summary).to eq(0)
        end
      end
    end
  end

  describe 'with assessments' do
    before(:all) do
      default_setup(default_ce_apr_setup_path)
    end

    after(:all) do
      cleanup
    end

    describe 'With default project' do
      before(:all) do
        run(default_filter, HudApr::Generators::CeApr::Fy2021::QuestionSix::QUESTION_NUMBER)
      end

      describe 'Q6a: Personally Identifiable Information' do
        it 'finds no SSN issues' do
          expect(report_result.answer(question: 'Q6a', cell: 'E3').summary).to eq(0)
        end
        it 'finds the missing DOB' do
          expect(report_result.answer(question: 'Q6a', cell: 'C4').summary).to eq(1)
        end
        it 'finds the DK/R races' do
          expect(report_result.answer(question: 'Q6a', cell: 'B5').summary).to eq(2)
        end
        it 'finds three total Race flags' do
          expect(report_result.answer(question: 'Q6a', cell: 'E5').summary).to eq(3)
        end
        it 'finds four clients with issues' do
          expect(report_result.answer(question: 'Q6a', cell: 'E8').summary).to eq(4)
        end
      end
    end
  end
end
