###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'path_context'

RSpec.describe HudPathReport::Generators::Fy2021::QuestionTwentySix, type: :model do
  include_context 'path context FY2021'

  before(:all) do
    default_setup
    run(default_filter, HudPathReport::Generators::Fy2021::QuestionTwentySix::QUESTION_NUMBER)
  end

  after(:all) do
    cleanup
  end

  describe 'genders' do
    it 'counts identifies as female' do
      expect(report_result.answer(question: 'Q26', cell: 'C2').summary).to eq(1)
    end
    it 'counts clients' do
      expect(report_result.answer(question: 'Q26', cell: 'C10').summary).to eq(2)
    end
  end

  describe 'ages' do
    it 'counts minors' do
      expect(report_result.answer(question: 'Q26', cell: 'C11').summary).to eq(1)
    end
    it 'counts ages 18-24' do
      expect(report_result.answer(question: 'Q26', cell: 'C12').summary).to eq(1)
    end
    it 'counts clients' do
      expect(report_result.answer(question: 'Q26', cell: 'C10').summary).to eq(2)
    end
  end

  describe 'race' do
    [1, 1, 0, 0, 0, 0, 0, 0].each_with_index do |count, index|
      it "counts by race: index: #{index}" do
        expect(report_result.answer(question: 'Q26', cell: 'C' + (index + 22).to_s).summary).to eq(count)
      end
    end
  end

  describe 'ethnicities' do
    it 'counts identifies as non-hispanic/latino' do
      expect(report_result.answer(question: 'Q26', cell: 'C31').summary).to eq(1)
    end
    it 'counts clients' do
      expect(report_result.answer(question: 'Q26', cell: 'C36').summary).to eq(2)
    end
  end

  describe 'veteran statuses' do
    it 'counts veterans' do
      expect(report_result.answer(question: 'Q26', cell: 'C37').summary).to eq(1)
    end
    it 'counts clients' do
      expect(report_result.answer(question: 'Q26', cell: 'C42').summary).to eq(1)
    end
  end

  describe 'co-occurring disorder' do
    it 'counts yes' do
      expect(report_result.answer(question: 'Q26', cell: 'C43').summary).to eq(1)
    end
    it 'counts clients' do
      expect(report_result.answer(question: 'Q26', cell: 'C46').summary).to eq(2)
    end
  end

  describe 'soar connection' do
    it 'counts yes' do
      expect(report_result.answer(question: 'Q26', cell: 'C47').summary).to eq(1)
    end
    it 'counts clients' do
      expect(report_result.answer(question: 'Q26', cell: 'C52').summary).to eq(2)
    end
  end

  describe 'prior living situation' do
    it 'counts safe haven' do
      expect(report_result.answer(question: 'Q26', cell: 'C56').summary).to eq(1)
    end
    it 'counts clients' do
      # Line 57 is missing from spec, so subtract 1 from all lines after this poing
      expect(report_result.answer(question: 'Q26', cell: 'C84').summary).to eq(2)
    end
  end

  it 'counts clients with length of stay' do
    expect(report_result.answer(question: 'Q26', cell: 'C94').summary).to eq(0)
  end

  describe 'chronically homeless' do
    it 'counts yeses' do
      expect(report_result.answer(question: 'Q26', cell: 'C95').summary).to eq(0)
    end
    it 'counts clients' do
      expect(report_result.answer(question: 'Q26', cell: 'C98').summary).to eq(2)
    end
  end

  describe 'domestic violence' do
    it 'counts yeses' do
      expect(report_result.answer(question: 'Q26', cell: 'C99').summary).to eq(1)
    end
    it 'counts clients' do
      expect(report_result.answer(question: 'Q26', cell: 'C104').summary).to eq(1)
    end
  end
end
