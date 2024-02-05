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

RSpec.describe HudPathReport::Generators::Fy2024::QuestionTwentySix, type: :model do
  include_context 'path context FY2024'

  before(:all) do
    default_setup
    run(default_filter, HudPathReport::Generators::Fy2024::QuestionTwentySix::QUESTION_NUMBER)
  end

  after(:all) do
    cleanup
  end

  describe 'genders' do
    it 'counts identifies as woman' do
      expect(report_result.answer(question: 'Q26', cell: 'C2').summary).to eq(1)
    end
    it 'counts clients' do
      expect(report_result.answer(question: 'Q26', cell: 'C12').summary).to eq(2)
    end
  end

  describe 'ages' do
    it 'counts 17 and under' do
      expect(report_result.answer(question: 'Q26', cell: 'C13').summary).to eq(1)
    end
    it 'counts ages 18-24' do
      expect(report_result.answer(question: 'Q26', cell: 'C14').summary).to eq(1)
    end
    it 'counts clients' do
      expect(report_result.answer(question: 'Q26', cell: 'C23').summary).to eq(2)
    end
  end

  describe 'race' do
    [1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 2].each_with_index do |count, index|
      it "counts by race: index: #{index}" do
        expect(report_result.answer(question: 'Q26', cell: "C#{index + 24}").summary).to eq(count)
      end
    end
  end

  describe 'veteran statuses' do
    it 'counts veterans' do
      expect(report_result.answer(question: 'Q26', cell: 'C35').summary).to eq(1)
    end
    it 'counts clients' do
      expect(report_result.answer(question: 'Q26', cell: 'C40').summary).to eq(1)
    end
  end

  describe 'co-occurring disorder' do
    it 'counts yes' do
      expect(report_result.answer(question: 'Q26', cell: 'C41').summary).to eq(1)
    end
    it 'counts clients' do
      expect(report_result.answer(question: 'Q26', cell: 'C44').summary).to eq(2)
    end
  end

  describe 'soar connection' do
    it 'counts yes' do
      expect(report_result.answer(question: 'Q26', cell: 'C45').summary).to eq(1)
    end
    it 'counts clients' do
      expect(report_result.answer(question: 'Q26', cell: 'C50').summary).to eq(2)
    end
  end

  describe 'prior living situation' do
    it 'counts safe haven' do
      expect(report_result.answer(question: 'Q26', cell: 'C54').summary).to eq(1)
    end
    it 'counts clients' do
      expect(report_result.answer(question: 'Q26', cell: 'C78').summary).to eq(2)
    end
  end

  it 'counts clients with length of stay' do
    expect(report_result.answer(question: 'Q26', cell: 'C88').summary).to eq(0)
  end

  describe 'chronically homeless' do
    it 'counts yeses' do
      expect(report_result.answer(question: 'Q26', cell: 'C89').summary).to eq(0)
    end
    it 'counts clients' do
      expect(report_result.answer(question: 'Q26', cell: 'C92').summary).to eq(2)
    end
  end

  describe 'domestic violence' do
    it 'counts yeses' do
      expect(report_result.answer(question: 'Q26', cell: 'C93').summary).to eq(0)
    end
    it 'counts clients' do
      expect(report_result.answer(question: 'Q26', cell: 'C98').summary).to eq(1)
    end
  end
end
