###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'apr_context'

RSpec.describe HudApr::Generators::Apr::Fy2020::QuestionTwenty, type: :model do
  include_context 'apr context'

  before(:all) do
    default_setup
    run(default_filter, HudApr::Generators::Apr::Fy2020::QuestionTwenty::QUESTION_NUMBER)
  end

  after(:all) do
    cleanup
  end

  describe 'Q20a: Type of Non-Cash Benefit Sources' do
  end

  describe 'Q20b: Number of Non-Cash Benefit Sources' do
    it 'no benefits at start' do
      expect(report_result.answer(question: 'Q20b', cell: 'B2').summary).to eq(2)
    end

    it 'no benefits at annual assessment' do
      expect(report_result.answer(question: 'Q20b', cell: 'C2').summary).to eq(1)
    end

    it 'no benefits at exit' do
      expect(report_result.answer(question: 'Q20b', cell: 'D2').summary).to eq(1)
    end
  end
end
