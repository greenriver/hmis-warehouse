###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'apr_context'

RSpec.describe HudApr::Generators::Apr::Fy2021::QuestionTwelve, type: :model do
  include_context 'apr context'

  before(:all) do
    default_setup
    run(default_filter, HudApr::Generators::Apr::Fy2021::QuestionTwelve::QUESTION_NUMBER)
  end

  after(:all) do
    cleanup
  end

  describe 'Q12a: Race' do
    it 'totals clients in households' do
      sum = report_result.answer(question: 'Q12a', cell: 'C10').summary +
        report_result.answer(question: 'Q12a', cell: 'D10').summary +
        report_result.answer(question: 'Q12a', cell: 'E10').summary +
        report_result.answer(question: 'Q12a', cell: 'F10').summary

      expect(report_result.answer(question: 'Q12a', cell: 'B10').summary).to eq(sum)
    end
  end

  describe 'Q12b: Ethnicity' do
    it 'totals clients in households' do
      sum = report_result.answer(question: 'Q12b', cell: 'C6').summary +
        report_result.answer(question: 'Q12b', cell: 'D6').summary +
        report_result.answer(question: 'Q12b', cell: 'E6').summary +
        report_result.answer(question: 'Q12b', cell: 'F6').summary

      expect(report_result.answer(question: 'Q12b', cell: 'B6').summary).to eq(sum)
    end
  end
end
