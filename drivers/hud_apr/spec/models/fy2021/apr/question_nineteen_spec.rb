###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'apr_context'

RSpec.describe HudApr::Generators::Apr::Fy2021::QuestionNineteen, type: :model do
  include_context 'apr context FY2021'

  before(:all) do
    default_setup
    run(default_filter, HudApr::Generators::Apr::Fy2021::QuestionNineteen::QUESTION_NUMBER)
  end

  after(:all) do
    cleanup
  end

  describe 'Q19a1: Client Cash Income Change - Income Source - by Start and Latest Status' do
    it 'has a client with earned increase from start and annual assessment' do
      expect(report_result.answer(question: 'Q19a1', cell: 'E2').summary).to eq(1)
      expect(report_result.answer(question: 'Q19a1', cell: 'E3').summary).to eq('1.00')
    end

    it 'counts start and annual assessment population' do
      expect(report_result.answer(question: 'Q19a1', cell: 'H2').summary).to eq(2)
    end
  end

  describe 'Q19a2: Client Cash Income Change - Income Source - by Start and Exit' do
  end

  describe 'Q19b: Disabling Conditions and Income for Adults at Exit' do
    it 'finds the disabled exit with no income' do
      expect(report_result.answer(question: 'Q19b', cell: 'B13').summary).to eq(1)
      expect(report_result.answer(question: 'Q19b', cell: 'B14').summary).to eq(1)
    end
  end
end
