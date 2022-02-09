###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'apr_context'

RSpec.describe HudApr::Generators::Apr::Fy2020::QuestionSix, type: :model do
  include_context 'apr context'

  before(:all) do
    default_setup
  end

  after(:all) do
    cleanup
  end

  describe 'With default project' do
    before(:all) do
      run(default_filter, HudApr::Generators::Apr::Fy2020::QuestionSix::QUESTION_NUMBER)
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

    describe 'Q6b: Data Quality: Universal Data Elements' do
      it 'hoh denominator is correct' do
        expect(report_result.answer(question: 'Q6b', cell: 'C5').summary).to eq('0.0000')
      end
    end

    describe 'Q6c: Data Quality: Income and Housing Data Quality' do
      it 'counts at least one income' do
        answer = report_result.answer(question: 'Q6c', cell: 'C3').summary
        expect(answer).not_to eq(nil)
        expect(answer).not_to eq('1.0000')
      end
    end

    describe 'Q6d: Data Quality: Chronic Homelessness' do
      it 'counts adults and hoh' do
        expect(report_result.answer(question: 'Q6d', cell: 'B5').summary).to eq(8)
      end

      it 'counts at least one invalid record' do
        answer = report_result.answer(question: 'Q6d', cell: 'H5').summary
        expect(answer).not_to eq(nil)
        expect(answer).not_to eq('0.0000')
      end
    end

    describe 'Q6e: Data Quality: Timeliness' do
      it 'sees the starts' do
        expect(report_result.answer(question: 'Q6e', cell: 'B2').summary).to eq(1)
      end

      it 'sees the exits' do
        expect(report_result.answer(question: 'Q6e', cell: 'C2').summary).to eq(4)
      end
    end
  end

  describe 'Q6f: Data Quality: Inactive Records: Street Outreach and Emergency Shelter' do
    before(:all) do
      run(night_by_night_shelter, HudApr::Generators::Apr::Fy2020::QuestionSix::QUESTION_NUMBER)
    end

    it 'sees the stayers' do
      expect(report_result.answer(question: 'Q6f', cell: 'B2').summary).to eq(5)
    end

    it 'there was at least one a contact' do
      answer = report_result.answer(question: 'Q6f', cell: 'D2').summary
      expect(answer).not_to eq(nil)
      expect(answer).not_to eq('1.0000')
    end
  end
end
