###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'ce_apr_context'

RSpec.describe HudApr::Generators::CeApr::Fy2021::QuestionTen, type: :model do
  include_context 'ce apr context'

  before(:all) do
    default_setup(default_ce_apr_setup_path)
    run(default_filter, HudApr::Generators::CeApr::Fy2021::QuestionTen::QUESTION_NUMBER)
  end

  after(:all) do
    cleanup
  end

  describe 'Q10: Total Coordinated Entry Activity During the Year' do
    it 'Crisis Needs Assessment' do
      expect(report_result.answer(question: 'Q10', cell: 'B2').summary).to eq(7)
    end

    it 'Housing Needs Assessment' do
      expect(report_result.answer(question: 'Q10', cell: 'B3').summary).to eq(2)
    end

    it 'Referral to Prevention Assistance project' do
      expect(report_result.answer(question: 'Q10', cell: 'B4').summary).to eq(6)
    end

    it 'Problem Solving/Diversion/Rapid Resolution intervention or service Re-housed in safe alternative' do
      expect(report_result.answer(question: 'Q10', cell: 'F5').summary).to eq(2)
    end

    it 'Referral to scheduled Coordinated Entry Crisis Needs Assessment' do
      expect(report_result.answer(question: 'Q10', cell: 'B6').summary).to eq(1)
    end

    it 'Referral to post-placement/follow-up case management Enrolled in aftercare' do
      expect(report_result.answer(question: 'Q10', cell: 'G8').summary).to eq(1)
    end
  end
end
