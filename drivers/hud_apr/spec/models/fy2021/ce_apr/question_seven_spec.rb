###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'ce_apr_context'

RSpec.describe HudApr::Generators::CeApr::Fy2021::QuestionSeven, type: :model do
  include_context 'ce apr context FY2021'

  describe 'with no assessments' do
    before(:all) do
      default_setup(default_setup_path)
      run(default_filter, HudApr::Generators::CeApr::Fy2021::QuestionSeven::QUESTION_NUMBER)
    end

    after(:all) do
      cleanup
    end

    describe 'Q7a: Number of Persons Served' do
      it 'counts adults' do
        expect(report_result.answer(question: 'Q7a', cell: 'B2').summary).to eq(0)
      end

      it 'counts adults without children' do
        expect(report_result.answer(question: 'Q7a', cell: 'C2').summary).to eq(0)
      end

      it 'counts adults with children' do
        expect(report_result.answer(question: 'Q7a', cell: 'D2').summary).to eq(0)
      end
    end

    describe 'Q7b: Point-in-Time Count of Persons on the Last Wednesday' do
      # TODO: needs a 2, 3, 8, 9, 10, or 13 project
    end
  end
  describe 'with assessments' do
    before(:all) do
      default_setup(default_ce_apr_setup_path)
      run(default_filter, HudApr::Generators::CeApr::Fy2021::QuestionSeven::QUESTION_NUMBER)
    end

    after(:all) do
      cleanup
    end

    describe 'Q7a: Number of Persons Served' do
      it 'counts adults' do
        expect(report_result.answer(question: 'Q7a', cell: 'B2').summary).to eq(6)
      end

      it 'counts adults without children' do
        expect(report_result.answer(question: 'Q7a', cell: 'C2').summary).to eq(5)
      end

      it 'counts adults with children' do
        expect(report_result.answer(question: 'Q7a', cell: 'D2').summary).to eq(1)
      end
    end

    describe 'Q7b: Point-in-Time Count of Persons on the Last Wednesday' do
      # TODO: needs a 2, 3, 8, 9, 10, or 13 project
    end
  end
end
