###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'dq_context'

RSpec.describe HudDataQualityReport::Generators::Fy2020::QuestionOne, type: :model do
  include_context 'dq context'

  describe 'with default filters' do
    before(:all) do
      default_setup
      run(default_filter, HudDataQualityReport::Generators::Fy2020::QuestionOne::QUESTION_NUMBER)
    end

    after(:all) do
      cleanup
    end

    it 'counts people served' do
      expect(report_result.answer(question: 'Q1', cell: 'B1').summary).to eq(9)
    end

    it 'counts adults' do
      expect(report_result.answer(question: 'Q1', cell: 'B2').summary).to eq(6)
    end

    it 'counts children' do
      expect(report_result.answer(question: 'Q1', cell: 'B3').summary).to eq(2)
    end

    it 'counts missing age' do
      expect(report_result.answer(question: 'Q1', cell: 'B4').summary).to eq(1)
    end

    it 'counts leavers' do
      expect(report_result.answer(question: 'Q1', cell: 'B5').summary).to eq(4)
    end

    it 'counts adult leavers' do
      expect(report_result.answer(question: 'Q1', cell: 'B6').summary).to eq(3)
    end

    it 'counts adult and head of household leavers' do
      expect(report_result.answer(question: 'Q1', cell: 'B7').summary).to eq(3)
    end

    it 'counts stayers' do
      expect(report_result.answer(question: 'Q1', cell: 'B8').summary).to eq(5)
    end

    it 'counts adult stayers' do
      expect(report_result.answer(question: 'Q1', cell: 'B9').summary).to eq(3)
    end

    it 'counts veterans' do
      expect(report_result.answer(question: 'Q1', cell: 'B10').summary).to eq(2)
    end

    it 'counts chronically homeless persons' do
      expect(report_result.answer(question: 'Q1', cell: 'B11').summary).to eq(1)
    end

    it 'counts under 25' do
      expect(report_result.answer(question: 'Q1', cell: 'B12').summary).to eq(8)
    end

    it 'counts under 25 with children' do
      expect(report_result.answer(question: 'Q1', cell: 'B13').summary).to eq(1)
    end

    it 'counts adult heads of household' do
      expect(report_result.answer(question: 'Q1', cell: 'B14').summary).to eq(6)
    end

    it 'counts child and unknown age heads of household' do
      expect(report_result.answer(question: 'Q1', cell: 'B15').summary).to eq(2)
    end

    it 'counts heads of household and stayers over 365 days' do
      expect(report_result.answer(question: 'Q1', cell: 'B16').summary).to eq(4)
    end
  end

  describe 'When filtering with a specific race' do
    before(:all) do
      default_setup
      run(race_filter, HudDataQualityReport::Generators::Fy2020::QuestionOne::QUESTION_NUMBER)
    end
    it 'counts people served' do
      expect(report_result.answer(question: 'Q1', cell: 'B1').summary).to eq(1)
    end
  end

  describe 'When filtering with a specific age' do
    before(:all) do
      default_setup
      run(age_filter, HudDataQualityReport::Generators::Fy2020::QuestionOne::QUESTION_NUMBER)
    end
    it 'counts people served' do
      expect(report_result.answer(question: 'Q1', cell: 'B1').summary).to eq(2)
    end
  end
end
