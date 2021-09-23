###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'apr_context'

RSpec.describe HudApr::Generators::Apr::Fy2021::QuestionFourteen, type: :model do
  include_context 'apr context FY2021'

  before(:all) do
    default_setup
    run(default_filter, HudApr::Generators::Apr::Fy2021::QuestionFourteen::QUESTION_NUMBER)
  end

  after(:all) do
    cleanup
  end

  describe 'Q14a: Domestic Violence History' do
    it 'counts 1 w/o children' do
      expect(report_result.answer(question: 'Q14a', cell: 'B2').summary).to eq(1)
      expect(report_result.answer(question: 'Q14a', cell: 'C2').summary).to eq(1)
    end

    it 'counts 1 no answer w/ children' do
      expect(report_result.answer(question: 'Q14a', cell: 'D5').summary).to eq(1)
    end
  end

  describe 'Q14b: Persons Fleeing Domestic Violence' do
    it 'counts 1 fleeing' do
      expect(report_result.answer(question: 'Q14b', cell: 'B2').summary).to eq(1)
    end
  end
end
