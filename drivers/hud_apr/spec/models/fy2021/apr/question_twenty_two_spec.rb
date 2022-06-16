###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'apr_context'

RSpec.describe HudApr::Generators::Apr::Fy2021::QuestionTwentyTwo, type: :model do
  include_context 'apr context FY2021'

  before(:all) do
    default_setup
    run(default_filter, HudApr::Generators::Apr::Fy2021::QuestionTwentyTwo::QUESTION_NUMBER)
  end

  after(:all) do
    cleanup
  end

  describe 'Q22a1: Length of Participation - CoC Projects' do
    it 'finds all clients' do
      expect(report_result.answer(question: 'Q22a1', cell: 'B6').summary).to eq(5)
      expect(report_result.answer(question: 'Q22a1', cell: 'B7').summary).to eq(4)
      expect(report_result.answer(question: 'Q22a1', cell: 'B13').summary).to eq(9)
    end

    it 'finds all leavers' do
      expect(report_result.answer(question: 'Q22a1', cell: 'C6').summary).to eq(4)
      expect(report_result.answer(question: 'Q22a1', cell: 'C13').summary).to eq(4)
    end

    it 'finds all stayers' do
      expect(report_result.answer(question: 'Q22a1', cell: 'D6').summary).to eq(1)
      expect(report_result.answer(question: 'Q22a1', cell: 'D7').summary).to eq(4)
      expect(report_result.answer(question: 'Q22a1', cell: 'D13').summary).to eq(5)
    end
  end

  describe 'Q22b: Average and Median Length of Participation in Days' do
  end

  describe 'Q22c: Length of Time between Project Start Date and Housing Move-in Date' do
    it 'finds move in dates' do
      # FIXME: Add RRH/PSH enrollments to fixture
      expect(report_result.answer(question: 'Q22c', cell: 'B10').summary).to eq(0)
    end

    it 'finds leaver with no move in date' do
      # FIXME: Add RRH/PSH enrollments to fixture
      expect(report_result.answer(question: 'Q22c', cell: 'B12').summary).to eq(0)
    end
  end

  describe 'Q22e: Length of Time Prior to Housing - based on 3.917 Date Homelessness Started' do
  end
end
