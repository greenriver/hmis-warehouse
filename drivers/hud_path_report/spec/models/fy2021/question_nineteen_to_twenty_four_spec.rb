###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'path_context'

RSpec.describe HudPathReport::Generators::Fy2021::QuestionNineteenToTwentyFour, type: :model, ci_bucket: 'bucket-2' do
  include_context 'path context FY2021'

  before(:all) do
    default_setup
    run(default_filter, HudPathReport::Generators::Fy2021::QuestionNineteenToTwentyFour::QUESTION_NUMBER)
  end

  after(:all) do
    cleanup
  end

  describe 'at start' do
    describe 'income' do
      it 'counts yes' do
        expect(report_result.answer(question: 'Q19-Q24', cell: 'B3').summary).to eq(1)
      end

      it 'counts total' do
        expect(report_result.answer(question: 'Q19-Q24', cell: 'B8').summary).to eq(2)
      end
    end
    describe 'SSI/SSDI' do
      it 'counts yes' do
        expect(report_result.answer(question: 'Q19-Q24', cell: 'B10').summary).to eq(2)
      end
      it 'counts no' do
        expect(report_result.answer(question: 'Q19-Q24', cell: 'B11').summary).to eq(0)
      end
    end
  end

  describe 'leavers' do
    describe 'income' do
      it 'counts yes' do
        expect(report_result.answer(question: 'Q19-Q24', cell: 'C3').summary).to eq(1)
      end

      it 'counts total' do
        expect(report_result.answer(question: 'Q19-Q24', cell: 'C8').summary).to eq(1)
      end
    end
    describe 'SSI/SSDI' do
      it 'counts yes' do
        expect(report_result.answer(question: 'Q19-Q24', cell: 'C10').summary).to eq(0)
      end
      it 'counts no' do
        expect(report_result.answer(question: 'Q19-Q24', cell: 'C11').summary).to eq(1)
      end
    end
  end

  describe 'stayers' do
    describe 'income' do
      it 'counts yes' do
        expect(report_result.answer(question: 'Q19-Q24', cell: 'D3').summary).to eq(0)
      end

      it 'counts total' do
        expect(report_result.answer(question: 'Q19-Q24', cell: 'D8').summary).to eq(1)
      end
    end
    describe 'SSI/SSDI' do
      it 'counts yes' do
        expect(report_result.answer(question: 'Q19-Q24', cell: 'D10').summary).to eq(1)
      end
      it 'counts no' do
        expect(report_result.answer(question: 'Q19-Q24', cell: 'D11').summary).to eq(0)
      end
    end
  end
end
