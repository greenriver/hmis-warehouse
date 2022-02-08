###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'apr_context'

RSpec.describe HudApr::Generators::Apr::Fy2020::QuestionTwentyThree, type: :model do
  include_context 'apr context'

  before(:all) do
    default_setup
    run(default_filter, HudApr::Generators::Apr::Fy2020::QuestionTwentyThree::QUESTION_NUMBER)
  end

  after(:all) do
    cleanup
  end

  describe 'Q23c: Exit Destination' do
    it 'sees client exits to permanent destination' do
      expect(report_result.answer(question: 'Q23c', cell: 'B16').summary).to eq(3)
    end
    it 'sees client exits to temporary destinations' do
      expect(report_result.answer(question: 'Q23c', cell: 'B27').summary).to eq(1)
    end
    it 'computes the percentage of leavers to positive destinations' do
      expect(report_result.answer(question: 'Q23c', cell: 'B46').summary).to eq('0.7500')
    end
  end
end
