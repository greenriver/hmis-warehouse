###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'ce_apr_context'

RSpec.describe HudApr::Generators::CeApr::Fy2021::QuestionNine, type: :model do
  include_context 'ce apr context FY2021'

  before(:all) do
    default_setup(default_ce_apr_setup_path)
    run(default_filter, HudApr::Generators::CeApr::Fy2021::QuestionNine::QUESTION_NUMBER)
  end

  after(:all) do
    cleanup
  end

  describe 'Q9a: Assessment Type' do
    it 'phone assessments' do
      expect(report_result.answer(question: 'Q9a', cell: 'B2').summary).to eq(6)
    end
  end

  describe 'Q9b: Prioritization Status' do
    it 'on prioritization list' do
      expect(report_result.answer(question: 'Q9b', cell: 'B2').summary).to eq(7)
    end
  end

  describe 'Q9c: Access Events' do
    it 'Referral to Prevention Assistance project' do
      expect(report_result.answer(question: 'Q9c', cell: 'B2').summary).to eq(5)
    end

    it 'Problem Solving/Diversion/Rapid Resolution intervention or service' do
      expect(report_result.answer(question: 'Q9c', cell: 'B3').summary).to eq(1)
    end
  end

  describe 'Q9d: Referral Events' do
    it 'Post-placement/follow-up case management' do
      expect(report_result.answer(question: 'Q9d', cell: 'B2').summary).to eq(1)
    end

    it 'Result: Unsuccessful referral: provider rejected' do
      # Note even though we have one of these, it's not on an HoH
      expect(report_result.answer(question: 'Q9d', cell: 'B20').summary).to eq(0)
    end
  end
end
